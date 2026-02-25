import xml.etree.ElementTree as ET
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from models import RawHealthData, DailyMetrics

def parse_apple_health_xml(file_path: str, max_records: int = 500000) -> pd.DataFrame:
    """
    Given a path to an Apple Health export.xml, parses it iteratively to save memory
    and extracts relevant physiological records.
    """
    context = ET.iterparse(file_path, events=('end',))
    
    records = []
    count = 0
    
    # Types we care about for stress/mood prediction MVP
    target_types = {
        'HKQuantityTypeIdentifierHeartRate': 'HeartRate',
        'HKQuantityTypeIdentifierRestingHeartRate': 'RestingHeartRate',
        'HKQuantityTypeIdentifierHeartRateVariabilitySDNN': 'HRV',
        'HKQuantityTypeIdentifierRespiratoryRate': 'RespiratoryRate',
        'HKCategoryTypeIdentifierSleepAnalysis': 'SleepAnalysis'
    }
    
    for event, elem in context:
        if elem.tag == 'Record':
            type_str = elem.get('type')
            
            if type_str in target_types:
                val = elem.get('value')
                # Some types like SleepAnalysis use 'value' differently, but we capture it
                if 'HKCategoryValueSleepAnalysis' in str(val):
                    val = 1 if 'Asleep' in str(val) else 0 # Simple binary for asleep vs inbed
                elif val is not None:
                    try:
                        val = float(val)
                    except ValueError:
                        pass
                
                records.append({
                    'type': target_types[type_str],
                    'startDate': elem.get('startDate'),
                    'endDate': elem.get('endDate'),
                    'value': val
                })
                
            elem.clear()
            count += 1
            if count >= max_records:
                break
                
    if not records:
        return pd.DataFrame()
        
    df = pd.DataFrame(records)
    df['startDate'] = pd.to_datetime(df['startDate'])
    df['endDate'] = pd.to_datetime(df['endDate'])
    df['date'] = df['startDate'].dt.date
    
    return df

def aggregate_daily_metrics(df: pd.DataFrame, user_id: str) -> List[DailyMetrics]:
    """
    Takes a raw dataframe of Apple Health records and aggregates them by day 
    to form the DailyMetrics objects needed for Anomaly Detection.
    """
    if df.empty:
        return []
        
    metrics_list = []
    
    # Group by date
    grouped = df.groupby('date')
    
    for date_obj, group in grouped:
        # Separate the records by type for the day
        hr_df = group[group['type'] == 'HeartRate']
        rhr_df = group[group['type'] == 'RestingHeartRate']
        hrv_df = group[group['type'] == 'HRV']
        resp_df = group[group['type'] == 'RespiratoryRate']
        sleep_df = group[group['type'] == 'SleepAnalysis']
        
        # Calculate daily aggregates
        # Resting HR: prefer dedicated RHR records, fallback to average of all HR if needed
        rhr_avg = rhr_df['value'].mean() if not rhr_df.empty else (hr_df['value'].mean() if not hr_df.empty else None)
        
        # HRV RMSSD (Note: Apple Health exports SDNN, we use it as a proxy for HRV in this MVP)
        hrv_avg = hrv_df['value'].mean() if not hrv_df.empty else None
        
        # Respiratory 
        resp_avg = resp_df['value'].mean() if not resp_df.empty else None
        
        # Sleep Duration: sum of all time spent 'Asleep' (value=1)
        sleep_duration_hrs = None
        if not sleep_df.empty:
            asleep_df = sleep_df[sleep_df['value'] == 1].copy()
            if not asleep_df.empty:
                asleep_df['duration'] = (asleep_df['endDate'] - asleep_df['startDate']).dt.total_seconds() / 3600.0
                sleep_duration_hrs = asleep_df['duration'].sum()
        
        # Only create a metric if we have some data
        if any(v is not None for v in [rhr_avg, hrv_avg, resp_avg, sleep_duration_hrs]):
            metric = DailyMetrics(
                user_id=user_id,
                date=date_obj,
                rhr_avg=float(rhr_avg) if rhr_avg else None,
                hrv_rmssd=float(hrv_avg) if hrv_avg else None,  # Using SDNN as proxy
                sleep_duration_hrs=float(sleep_duration_hrs) if sleep_duration_hrs else None,
                respiratory_rate_avg=float(resp_avg) if resp_avg else None
            )
            metrics_list.append(metric)
            
    return metrics_list
    
def process_health_export(file_path: str, user_id: str) -> List[DailyMetrics]:
    """
    End-to-end processing pipeline for a physical export.xml file.
    """
    print(f"Parsing {file_path} for user {user_id}...")
    df = parse_apple_health_xml(file_path)
    print(f"Parsed {len(df)} relevant clinical records.")
    
    metrics = aggregate_daily_metrics(df, user_id)
    print(f"Aggregated into {len(metrics)} days of DailyMetrics.")
    
    return metrics

if __name__ == "__main__":
    # Test block to verify it works on the local export.xml
    export_path = '/Users/arushisaran/Documents/appleProject/apple_health_export/export.xml'
    test_metrics = process_health_export(export_path, "user_demo_123")
    
    # Print the last 5 days
    for m in sorted(test_metrics, key=lambda x: x.date)[-5:]:
        print(m.model_dump())
