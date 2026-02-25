import pandas as pd
from typing import List
from sklearn.ensemble import IsolationForest
from models import DailyMetrics, AnomalyReport

# For the MVP, since we don't have a reliable pre-trained HuggingFace time-series model
# that works completely out of the box for physiological "stress" without heavy configuration,
# we will use an instance of IsolationForest acting as a statistical stand-in for our "pre-trained" logic.
# In a true deployment, this block would be replaced by `from transformers import AutoModelForTimeSeries...`

def detect_anomalies(user_id: str, 
                     historical_metrics: List[DailyMetrics], 
                     today_metrics: DailyMetrics) -> AnomalyReport:
    """
    Given a rolling window of history (last 14 days), determines if today's metrics
    are anomalous (indicating a "stress event" or "moment worth talking about").
    """
    
    # 1. Prepare Feature Matrix
    # We expect features: RHR (higher is stress), HRV (lower is stress), Sleep (lower is stress)
    # If a feature is missing, we fill with the historical median to not trigger false alarms on missing data.
    
    records = []
    for m in historical_metrics + [today_metrics]:
        records.append({
            'rhr': m.rhr_avg,
            'hrv': m.hrv_rmssd,
            'sleep': m.sleep_duration_hrs
        })
        
    df = pd.DataFrame(records)
    
    # Fill NAs with the column median
    df.fillna(df.median(numeric_only=True), inplace=True)
    
    # If after filling median we still have NaNs (e.g. user never had Sleep data), fill with 0
    df.fillna(0, inplace=True) 

    # 2. Run our "Pre-Trained" statistical model
    # We train the Isolation Forest instantly on the past history to find the rolling baseline.
    # We use contamination=0.10, assuming 10% of days are 'stressful' or 'anomalous'.
    
    # Only run if we have enough history to form a baseline
    if len(historical_metrics) < 3:
        # Not enough data to be confident
        return AnomalyReport(
            user_id=user_id,
            date=today_metrics.date,
            is_stress_event=False,
            score=0.0
        )
        
    model = IsolationForest(contamination=0.10, random_state=42)
    model.fit(df)
    
    # 3. Predict anomaly for today (the last row)
    today_features = df.iloc[[-1]]
    
    # model.predict returns -1 for outliers, 1 for inliers
    prediction = model.predict(today_features)[0]
    
    # model.decision_function returns the anomaly score (lower means more anomalous)
    # We invert it so higher score = more anomalous for our report
    raw_score = model.decision_function(today_features)[0]
    normalized_score = float(-1.0 * raw_score) # Just to make positive = weird
    
    is_stress_event = (prediction == -1)
    
    # Simple Heuristic Fallback/Sanity Check:
    # If Isolation Forest flagged it, ensure it's because RHR went UP or Sleep went DOWN.
    # If they rested *better* than usual, it's anomalous but not necessarily a "stress event".
    if is_stress_event and len(df) > 1:
        hist_rhr_median = df['rhr'][:-1].median()
        today_rhr = df.iloc[-1]['rhr']
        
        # If today's HR is lower than median, it's likely a rest day, not stress.
        if today_rhr < hist_rhr_median:
            is_stress_event = False

    return AnomalyReport(
        user_id=user_id,
        date=today_metrics.date,
        is_stress_event=is_stress_event,
        score=normalized_score
    )

if __name__ == "__main__":
    from datetime import date, timedelta
    
    # Test our anomaly detection
    uid = "test_user_1"
    base_date = date.today()
    
    # Generate 14 days of "normal" baseline (RHR around 60, Sleep around 8)
    history = []
    for i in range(14, 0, -1):
        history.append(DailyMetrics(
            user_id=uid,
            date=base_date - timedelta(days=i),
            rhr_avg=60.0 + (i % 3), # slight variance 60, 61, 62
            sleep_duration_hrs=8.0
        ))
        
    # Generate a "stress" day (High HR, low sleep)
    stress_day = DailyMetrics(
        user_id=uid,
        date=base_date,
        rhr_avg=85.0, # significantly higher
        sleep_duration_hrs=4.2 # significantly lower
    )
    
    report = detect_anomalies(uid, history, stress_day)
    print(f"Stress Day Report: {report}")
    
    # Generate a "normal" day
    normal_day = DailyMetrics(
        user_id=uid,
        date=base_date,
        rhr_avg=61.0,
        sleep_duration_hrs=7.8
    )
    report_normal = detect_anomalies(uid, history, normal_day)
    print(f"Normal Day Report: {report_normal}")
