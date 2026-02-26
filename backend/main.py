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

app = FastAPI(
    title="Insight Journal MVP API",
    description="Backend API for Mental Health Tracker & Journaling App",
    version="1.0.0"
)

# --- MOCK DATABASE ---
# For the MVP scaffold before wiring Pinecone/Firestore keys, we will use in-memory stores
DB_METRICS: Dict[str, List[DailyMetrics]] = {}
DB_ANOMALIES: Dict[str, List[AnomalyReport]] = {}
DB_JOURNALS: Dict[str, List[JournalEntry]] = {}

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Insight Journal API is running"}

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
            # Direct insertion from our iOS App's HealthKit payload
            try:
                # The payload is expected to be a dict or a JSON string matching the DailyMetrics model
                import json
                
                # Check if it was parsed as string or raw dict
                data_dict = {}
                if isinstance(payload.payload, str):
                    # Sometimes quotes get escaped over HTTP Post, strip standard dict repr
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
            # Fallback to the XML file ingestion for older testing logic
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

        # Save to DB
        if uid not in DB_METRICS:
            DB_METRICS[uid] = []
        
        # Append only if it's new (or overwrite if same date for MVP simplicity)
        for m in user_metrics:
            DB_METRICS[uid] = [existing for existing in DB_METRICS[uid] if existing.date != m.date]
            DB_METRICS[uid].append(m)
        
        # 2. Run Anomaly Detection 
        sorted_metrics = sorted(DB_METRICS[uid], key=lambda x: x.date)
        today_metrics = sorted_metrics[-1]
        historical = sorted_metrics[:-1]
        
        anomaly = ml_engine.detect_anomalies(uid, historical, today_metrics)
        
        # Save Anomaly
        if uid not in DB_ANOMALIES:
            DB_ANOMALIES[uid] = []
        DB_ANOMALIES[uid].append(anomaly)
        
        response_payload = {
            "status": "success", 
            "days_processed": len(user_metrics),
            "latest_date": str(today_metrics.date),
            "anomaly_detected": anomaly.is_stress_event,
            "anomaly_score": anomaly.score
        }
        logger.info(f"API Response [/sync-health]: {response_payload}")
        return response_payload
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/daily-checkin", response_model=AgentResponse)
async def get_checkin_prompts(user_id: str):
    """
    Generates Agentic AI prompts based on recent data from the DB.
    """
    if user_id not in DB_METRICS or not DB_METRICS[user_id]:
        # Fallback if no data
        fallback_resp = agent.generate_daily_insights(
            user_id, 
            DailyMetrics(user_id=user_id, date=date.today()), 
            AnomalyReport(user_id=user_id, date=date.today(), is_stress_event=False, score=0.0)
        )
        logger.info(f"API Response [/daily-checkin fallback]: {fallback_resp.model_dump()}")
        return fallback_resp
        
    # Get latest
    latest_metrics = sorted(DB_METRICS[user_id], key=lambda x: x.date)[-1]
    
    # Get latest anomaly (should match date)
    latest_anomalies = sorted(DB_ANOMALIES.get(user_id, []), key=lambda x: x.date)
    latest_anomaly = latest_anomalies[-1] if latest_anomalies else AnomalyReport(user_id=user_id, date=latest_metrics.date, is_stress_event=False, score=0.0)
    
    # Get recent journals 
    recent_journals = DB_JOURNALS.get(user_id, [])[-3:] # Last 3
    
    # Ask Vertex Agent
    insights = agent.generate_daily_insights(user_id, latest_metrics, latest_anomaly, recent_journals)
    logger.info(f"API Response [/daily-checkin]: {insights.model_dump()}")
    return insights

@app.post("/api/v1/journal")
async def create_journal_entry(entry: JournalEntry):
    """
    Saves a user journal entry to the database and Pinecone.
    """
    if entry.user_id not in DB_JOURNALS:
        DB_JOURNALS[entry.user_id] = []
        
    DB_JOURNALS[entry.user_id].append(entry)
    
    # In a full deployment, this is where we'd hit Pinecone API and Firestore API
    # embedding = vertex_ai.get_text_embedding(entry.text_content)
    # pinecone_index.upsert(...)
    
    response_payload = {"status": "success", "message": "Journal saved", "entry_id": len(DB_JOURNALS[entry.user_id])}
    logger.info(f"API Response [/journal]: {response_payload}")
    return response_payload

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
