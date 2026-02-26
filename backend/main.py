from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from typing import Dict, Any, List
from datetime import date
from dotenv import load_dotenv
import logging

# Configure logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("api_logger")

# Load environment variables from .env file
load_dotenv()

# Import our custom modules
from models import RawHealthData, DailyMetrics, AnomalyReport, AgentResponse, JournalEntry
import ingestion
import ml_engine
import agent
import database

app = FastAPI(
    title="Insight Journal MVP API",
    description="Backend API for Mental Health Tracker & Journaling App",
    version="1.0.0"
)

# REPLACED: Mock DB removed in favor of Firestore in database.py

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Insight Journal API is running with Firestore"}

@app.post("/api/v1/sync-health")
async def sync_health_data(payload: RawHealthData):
    """
    Ingests raw health data, calculates daily metrics, and runs anomaly detection.
    This simulates receiving a payload from the iOS app representing recent data.
    """
    try:
        user_metrics = []
        uid = payload.user_id
        
        # 1. Ingest Data
        if payload.data_source == "apple_watch_healthkit":
            try:
                import json
                data_dict = {}
                if isinstance(payload.payload, str):
                    clean_str = payload.payload.replace("'", '"')
                    try:
                        data_dict = json.loads(clean_str)
                    except json.JSONDecodeError:
                        import ast
                        data_dict = ast.literal_eval(payload.payload)
                else:
                    data_dict = payload.payload
                
                print(f"Received health payload from user {uid}: {data_dict}")
                
                dm = DailyMetrics(
                    user_id=uid,
                    date=date.fromisoformat(data_dict.get("date", str(date.today())).split("T")[0]),
                    rhr_avg=data_dict.get("rhr_avg"),
                    hrv_rmssd=data_dict.get("hrv_rmssd"),
                    respiratory_rate_avg=data_dict.get("respiratory_rate_avg"),
                    sleep_duration_hrs=data_dict.get("sleep_duration_hrs")
                )
                user_metrics = [dm]
            except Exception as e:
                print(f"Error parsing HealthKit JSON: {e}")
                
        else:
            # Fallback to the XML file ingestion
            import tempfile
            import os
            
            if payload.payload.startswith('/'):
                file_path = payload.payload
            else:
                fd, file_path = tempfile.mkstemp(suffix=".xml")
                with os.fdopen(fd, 'w') as f:
                    f.write(payload.payload)
                    
            user_metrics = ingestion.process_health_export(file_path, payload.user_id)
            
            if not payload.payload.startswith('/'):
                os.remove(file_path)
            
        if not user_metrics:
            return {"status": "error", "message": "No valid metrics parsed."}

        # Save to Firestore
        for m in user_metrics:
            database.save_daily_metrics(uid, m)
        
        # 2. Run Anomaly Detection 
        historical = database.get_historical_metrics(uid)
        if not historical:
            # This should ideally not happen after saving above, but safety first
            return {"status": "error", "message": "Failed to retrieve historical data."}
            
        today_metrics = historical[-1]
        historical_metrics = historical[:-1]
        
        anomaly = ml_engine.detect_anomalies(uid, historical_metrics, today_metrics)
        
        # Save Anomaly to Firestore
        database.save_anomaly(uid, anomaly)
        
        response_payload = {
            "status": "success", 
            "days_processed": len(user_metrics),
            "latest_date": str(today_metrics.date),
            "anomaly_detected": anomaly.is_stress_event,
            "anomaly_score": anomaly.score,
            "metrics_summary": {
                "rhr": today_metrics.rhr_avg,
                "hrv": today_metrics.hrv_rmssd,
                "respiratory_rate": today_metrics.respiratory_rate_avg,
                "sleep_hrs": today_metrics.sleep_duration_hrs
            }
        }
        logger.info(f"API Response [/sync-health]: {response_payload}")
        return response_payload
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/daily-checkin", response_model=AgentResponse)
async def get_checkin_prompts(user_id: str):
    """
    Generates Agentic AI prompts based on recent data from Firestore.
    """
    historical_metrics = database.get_historical_metrics(user_id)
    if not historical_metrics:
        # Fallback if no data
        fallback_resp = agent.generate_daily_insights(
            user_id, 
            DailyMetrics(user_id=user_id, date=date.today()), 
            AnomalyReport(user_id=user_id, date=date.today(), is_stress_event=False, score=0.0)
        )
        logger.info(f"API Response [/daily-checkin fallback]: {fallback_resp.model_dump()}")
        return fallback_resp
        
    # Get latest
    latest_metrics = historical_metrics[-1]
    
    # Get latest anomaly from Firestore
    latest_anomaly = database.get_latest_anomaly(user_id)
    if not latest_anomaly or latest_anomaly.date != latest_metrics.date:
        latest_anomaly = AnomalyReport(user_id=user_id, date=latest_metrics.date, is_stress_event=False, score=0.0)
    
    # Get recent journals from Firestore
    recent_journals = database.get_recent_journals(user_id, limit=3)
    
    # Ask Vertex Agent
    insights = agent.generate_daily_insights(user_id, latest_metrics, latest_anomaly, recent_journals)
    logger.info(f"API Response [/daily-checkin]: {insights.model_dump()}")
    return insights

@app.post("/api/v1/journal")
async def create_journal_entry(entry: JournalEntry):
    """
    Saves a user journal entry to Firestore.
    """
    database.save_journal(entry.user_id, entry)
    
    response_payload = {"status": "success", "message": "Journal saved to Firestore"}
    logger.info(f"API Response [/journal]: {response_payload}")
    return response_payload

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
