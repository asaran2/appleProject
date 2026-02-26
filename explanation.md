# Insight Journal MVP: Code Explanation & Walkthrough

This document outlines how the full data pipeline operates in the Insight Journal MVP, tracing the journey from the user's Apple Watch to the AI-generated journaling prompts on the screen.

## 1. Data Collection (iOS Frontend)
The journey begins entirely on the user's physical device within the iOS app.

* **`HealthKitManager.swift`**: This file is responsible for asking the user for permission and securely querying their Apple Health data (which is collected passively by their Apple Watch/iPhone).
  * Specifically, it calls the `fetchTodayMetrics()` method to calculate the discrete average of metrics like **Resting Heart Rate** and **HRV (`heartRateVariabilitySDNN`)** over the course of today (beginning at midnight).
  * It also parses through `.sleepAnalysis` events to calculate the total hours explicitly spent purely "Asleep".
* **`InsightViewModel.swift`**: Once the features are aggregated into a daily summary payload, this ViewModel fires a POST request, sending the JSON payload over the local network to your Python backend's `/sync-health` endpoint.

## 2. Ingestion & Storage (Python Backend)
The Python FastAPI server (`main.py`) acts as the brains of the operation. 

* **`/sync-health` Endpoint (`main.py`)**: When the backend receives the JSON payload from the iPhone, it unpacks it and creates a `DailyMetrics` object. 
* **Database Mock (`main.py`)**: For the hackathon MVP, instead of writing to an external database like Firebase or PostgreSQL, the records are appended to an in-memory dictionary (`DB_METRICS`). This allows the server to keep a running "historical baseline" for the user while the server is alive.
* **Fallback Ingestion (`ingestion.py`)**: The backend also contains XML parsing logic (`process_health_export`) designed to scrape huge data dumps (`export.xml`) directly from the Apple Health app for local offline testing and modeling purposes.

## 3. Threat/Anomaly Detection (Machine Learning)
After the data is saved, the backend immediately checks if today was a stressful day.

* **`ml_engine.py`**: The server passes the user's short-term history (e.g., the last 14 days of `DailyMetrics`) and today's new metrics into `detect_anomalies()`.
* **Isolation Forest**: Because human physiological baselines vary wildly between individuals, we don't use a static "one size fits all" pre-trained model. Instead, we use a scikit-learn unsupervised model (`IsolationForest`). The script builds a Pandas DataFrame of the user's rolling baseline and trains the model **on the fly**.
* It then asks the model: *"Statistically speaking, based on how this specific user usually sleeps and rests, is today an extreme outlier?"* 
* If the Isolation Forest flags the day as an anomaly (e.g., heavily elevated heart rate + low sleep), it returns an `AnomalyReport` flagging it as a `stress_event`.

## 4. Agentic AI (Google Gemini Prompt Generation)
Once the app knows *if* the user is stressed, it needs to figure out *what* to ask them. The iOS app triggers a GET request to `/daily-checkin` right after syncing the data.

* **`agent.py`**: The `generate_daily_insights()` function takes the raw data (`DailyMetrics`), the ML output (`AnomalyReport`), and any past `JournalEntries` the user recently logged, and formats them into a large string context. 
* **Gemini LLM**: It passes this strict context into the Google Gemini 2.5 Flash model alongside a System Prompt instructing it to act as an empathetic Wellbeing Coach. 
* If there is an anomaly, the LLM is instructed to ask questions linking their physiology (e.g., poor sleep) to their mood.
* The LLM responds in strict JSON format containing two personalized journaling prompts and a short daily summary.

## 5. UI Presentation
Finally, the JSON produced by Gemini is passed back down the HTTP response out of the Python backend and back into the iOS App (`InsightViewModel.swift`), which updates its `@Published` variables, rendering the AI-generated questions beautifully on the screen for the user to answer via text or mood sliders!
