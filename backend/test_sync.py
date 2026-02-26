import json
import urllib.request
import urllib.error
from datetime import datetime

# Adjust the URL if your backend is running on a different port or through a tunnel
BASE_URL = "http://localhost:8080/api/v1"

def test_sync_health():
    print(f"--- Testing /sync-health endpoint ---")
    
    # Mock data that looks like what HealthKitManager pulls
    payload = {
        "user_id": "arushi_demo_1",
        "data_source": "apple_watch_healthkit",
        "payload": {
            "date": datetime.now().isoformat(),
            "rhr_avg": 72.5,
            "hrv_rmssd": 55.2,
            "respiratory_rate_avg": 16.0,
            "sleep_duration_hrs": 7.5
        }
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(f"{BASE_URL}/sync-health", data=data, headers={'Content-Type': 'application/json'})
    
    try:
        with urllib.request.urlopen(req) as response:
            status = response.getcode()
            response_data = json.loads(response.read().decode('utf-8'))
            print(f"Status Code: {status}")
            print(f"Response: {json.dumps(response_data, indent=2)}")
            
            if status == 200:
                print("\n✅ Backend successfully processed health analytics!")
            else:
                print("\n❌ Backend failed to process health data.")
    except urllib.error.URLError as e:
        print(f"\n❌ Error connecting to backend: {e}")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

def test_get_checkin():
    print(f"\n--- Testing /daily-checkin endpoint ---")
    
    user_id = "arushi_demo_1"
    url = f"{BASE_URL}/daily-checkin?user_id={user_id}"
    
    try:
        with urllib.request.urlopen(url) as response:
            status = response.getcode()
            response_data = json.loads(response.read().decode('utf-8'))
            print(f"Status Code: {status}")
            print(f"Response: {json.dumps(response_data, indent=2)}")
            
            if status == 200:
                print("\n✅ AI Engine successfully generated insights!")
            else:
                print("\n❌ AI Engine failed to generate insights.")
    except urllib.error.URLError as e:
        print(f"\n❌ Error connecting to backend: {e}")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

if __name__ == "__main__":
    test_sync_health()
    test_get_checkin()
