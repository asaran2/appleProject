# Insight Journal MVP
**Core user promise:** “Your watch + a few check‑ins per day → personalized mental‑health reflections that connect how you feel with how you live (sleep, activity, stress).”

Think of existing mental‑health journaling apps (Stoic, 5 Minute Journal) that combine prompts, mood tracking, and insights as your UX benchmark, but with deeper health data integration and personalization.

## 1. Key flows (MVP)

**Onboarding**
- Ask goals (stress, mood, sleep, productivity).
- Ask notification windows for check‑ins.
- Request HealthKit permissions (heart rate, HRV, sleep, activity, State of Mind, etc.).

**Daily loop**
- App ingests watch/HealthKit data passively.
- Anomaly/interesting‑pattern detector flags “moments worth talking about.”
- Agentic AI generates 2–3 contextual questions (morning, afternoon, night).
- User answers with quick taps + optional free‑text journaling.

**Insights**
- Daily card: “Today’s story” tying physiology + mood + behaviors.
- Weekly view: patterns, correlations, gentle suggestions (non‑clinical).

## 2. High‑level architecture

**iOS app**
- SwiftUI UI, HealthKit integration, local storage of raw metrics & user inputs.
- Schedules notifications, displays prompts, basic trend visuals.
- Handles all HealthKit reads/writes.

**Backend + ML layer (Google Cloud / FastAPI)**
- Ingests time‑series features from the device (aggregated or sampled).
- Runs anomaly detection and trend analysis over heart rate, HRV, sleep, steps, etc.
- Stores user‑level baselines and feature summaries for privacy and cost efficiency.

**Agentic AI layer (Google Agentic AI on Vertex / AI Agents)**
- An AI agent orchestrates tasks: “given new data + existing baseline + user’s past journals, decide whether to prompt, what to ask, and how to summarize.”
- Uses LLM tools to query analytics APIs, generate questions, create daily/weekly narratives.

**Data store**
- User profile (goals, preferences), embeddings/summaries of past journals, aggregated health features, anomaly flags.

## 3. Data & feature design

**Data sources (MVP)**
From HealthKit (where available and user‑granted):
- Heart rate, HRV, resting HR.
- Sleep (in‑bed vs asleep, duration, efficiency).
- Activity: steps, active energy, exercise minutes.

From your app:
- Time‑stamped mood ratings.
- Short multiple‑choice answers (energy, focus, stress).
- Free‑text journal entries.

**Feature engineering basics**
- Daily aggregates: min/max/mean heart rate, HRV, sleep duration, time‑to‑bed, sleep regularity, step count.
- Short‑term deviations: z‑score of today vs 14‑day baseline.
- Event‑based windows: features feeding the agent from the "last 2 hours before check-in".

## 4. Anomaly and pattern detection (pure ML)
- **Baseline:** Per‑user rolling baseline over the last 7–14 days.
- **Detector:** Uses an unsupervised machine learning method (like an Isolation Forest) trained on the fly on the user's historical data.
- **Triggers:** Flags a window as “interesting” if today’s metric heavily deviates, or if the Isolation Forest anomaly score crosses a high threshold. These anomaly snippets become triggers for personalized journaling prompts.

## 5. Agentic AI layer: turning data into questions & insights
Define a “Wellbeing Coach Agent” with these capabilities:
- **Perception tools:** Analyze recent health metrics, anomalies, past journals, and user goals.
- **Decision logic:** Decide whether to nudge now and decide the prompt “theme” (sleep, stress, energy, joy, productivity).
- **Question generation:** Craft 2–3 short questions inspired by positive psychology.
- **Insight generation:** Output a "One-paragraph story" daily, and short bullet insights weekly.


## 6. How to Run This MVP

### Backend (FastAPI + Python)

1. Open your terminal and navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Activate the virtual environment (assuming macOS/Linux):
   ```bash
   source venv/bin/activate
   ```
3. Install the dependencies (if you haven't already):
   ```bash
   pip install -r requirements.txt
   ```
4. Add your `.env` configuration for Google Cloud or Pinecone if required by the models.
5. Start the backend server:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8080
   ```

### Exposing the Backend (Serveo Tunnel)

To allow the iOS device to communicate with your local backend, expose it to the internet:

1. Open a **new** terminal window and navigate to the `backend` directory.
2. Run the Serveo SSH tunnel command:
   ```bash
   ssh -R 80:localhost:8080 serveo.net
   ```
3. Serveo will output a forwarding URL (e.g., `https://[RANDOM_ID].serveousercontent.com`). **Copy this URL.**

*Note: If the tunnel times out or you receive a `502 Bad Gateway` error later on, simply restart this command to generate a new URL.*

### Frontend (iOS App + Swift)

1. Open Xcode.
2. Navigate to `mentalHealth/mentalHealth.xcodeproj` and open it.
3. Open `mentalHealth/ViewModels/InsightViewModel.swift`.
4. Update the `backendURL` property with your new Serveo URL, appending `/api/v1` to the end:
   ```swift
   private let backendURL = "https://[COPIED_SERVEO_URL]/api/v1"
   ```
5. Select your target device (e.g., your iPhone or a Simulator with HealthKit enabled).
6. Press the **Play** (Build and Run) button or `Cmd + R` to run the app. Make sure to allow HealthKit permissions when prompted.
