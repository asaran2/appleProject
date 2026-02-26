import os
from google.cloud import firestore
from datetime import datetime, date, time
from typing import List, Optional
from models import DailyMetrics, AnomalyReport, JournalEntry

# Initialize Firestore
# It will look for GOOGLE_APPLICATION_CREDENTIALS environment variable
# If not found, it might use the default project/account if logged in via `gcloud`
db = firestore.Client()

def date_to_datetime(d: date) -> datetime:
    """Converts a date object to a datetime object at midnight."""
    return datetime.combine(d, time.min)

def save_daily_metrics(user_id: str, metrics: DailyMetrics):
    """Saves or updates daily metrics for a user."""
    doc_id = f"{user_id}_{metrics.date.isoformat()}"
    doc_ref = db.collection("users").document(user_id).collection("metrics").document(doc_id)
    
    # Convert Pydantic model to dict, handling date conversion
    data = metrics.model_dump()
    data["date"] = metrics.date.isoformat() # Store as string for easy querying/ID
    
    doc_ref.set(data)

def get_historical_metrics(user_id: str) -> List[DailyMetrics]:
    """Fetches all historical metrics for a user, sorted by date."""
    docs = db.collection("users").document(user_id).collection("metrics").order_by("date").stream()
    
    metrics_list = []
    for doc in docs:
        data = doc.to_dict()
        # Ensure date is parsed back correctly
        if isinstance(data["date"], str):
            data["date"] = date.fromisoformat(data["date"])
        metrics_list.append(DailyMetrics(**data))
    
    return metrics_list

def save_anomaly(user_id: str, anomaly: AnomalyReport):
    """Saves an anomaly report for a user."""
    doc_id = f"{user_id}_{anomaly.date.isoformat()}"
    doc_ref = db.collection("users").document(user_id).collection("anomalies").document(doc_id)
    
    data = anomaly.model_dump()
    data["date"] = anomaly.date.isoformat()
    
    doc_ref.set(data)

def get_latest_anomaly(user_id: str) -> Optional[AnomalyReport]:
    """Fetches the most recent anomaly report for a user."""
    query = db.collection("users").document(user_id).collection("anomalies").order_by("date", direction=firestore.Query.DESCENDING).limit(1)
    results = list(query.stream())
    
    if not results:
        return None
        
    data = results[0].to_dict()
    if isinstance(data["date"], str):
        data["date"] = date.fromisoformat(data["date"])
    return AnomalyReport(**data)

def save_journal(user_id: str, journal: JournalEntry):
    """Saves a journal entry for a user."""
    doc_ref = db.collection("users").document(user_id).collection("journals").document()
    
    data = journal.model_dump()
    # Pydantic's model_dump handles datetime typically, 
    # but Firestore likes Native Python datetimes
    doc_ref.set(data)

def get_recent_journals(user_id: str, limit: int = 3) -> List[JournalEntry]:
    """Fetches the most recent journal entries for a user."""
    query = db.collection("users").document(user_id).collection("journals").order_by("timestamp", direction=firestore.Query.DESCENDING).limit(limit)
    results = query.stream()
    
    journals = []
    for doc in results:
        data = doc.to_dict()
        data["id"] = doc.id
        journals.append(JournalEntry(**data))
    
    return journals
