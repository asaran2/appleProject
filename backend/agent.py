import os
import json
from datetime import date
from typing import List
from models import DailyMetrics, AnomalyReport, AgentResponse, JournalEntry
import google.generativeai as genai

# Initialize Gemini API
api_key = os.getenv("GEMINI_API_KEY", "")
if api_key:
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-2.5-flash')
else:
    print("Warning: GEMINI_API_KEY not found in environment.")
    model = None

def _format_context_for_prompt(today_metrics: DailyMetrics, 
                               anomaly: AnomalyReport, 
                               past_journals: List[JournalEntry]) -> str:
    """
    Constructs the data context string to feed to the LLM.
    """
    
    context = f"Today's Date: {today_metrics.date}\\n"
    context += f"Physiology Metrics:\\n"
    if today_metrics.rhr_avg:
        context += f"- Resting Heart Rate: {today_metrics.rhr_avg:.1f} bpm\\n"
    if today_metrics.sleep_duration_hrs:
        context += f"- Sleep Duration: {today_metrics.sleep_duration_hrs:.1f} hours\\n"
    if today_metrics.hrv_rmssd:
        context += f"- HRV: {today_metrics.hrv_rmssd:.1f} ms\\n"
        
    context += f"\\nSystem ML Flagged an Anomaly: {anomaly.is_stress_event}\\n"
    
    if past_journals:
        context += "\\nRecent Journal Entries (for context):\\n"
        for j in past_journals:
            context += f"[{j.timestamp.strftime('%Y-%m-%d')}] Mood: {j.mood_score}/10 - '{j.text_content}'\\n"
            
    return context

def generate_daily_insights(user_id: str, 
                            today_metrics: DailyMetrics, 
                            anomaly: AnomalyReport,
                            past_journals: List[JournalEntry] = []) -> AgentResponse:
    """
    Uses Google Vertex AI (Gemini) to craft personalized journal prompts and a daily summary
    based on the user's physiological data and ML anomaly detection.
    """
    
    # If Vertex AI isn't configured, fallback gracefully for the MVP testing
    if not model:
        return AgentResponse(
            user_id=user_id,
            date=today_metrics.date,
            prompts=[
                "How did your sleep quality impact your energy today?",
                "What's one thing that increased your heart rate or stress today?"
            ],
            daily_summary="You had some interesting physiological patterns today. Let's reflect on them."
        )

    system_instruction = """
    You are an empathetic, insightful Wellbeing Coach Agent.
    Your goal is to help the user connect their biological data (heart rate, sleep) to their mental state.
    
    Based on the provided data context:
    1. If there's an anomaly (stress event), gently ask them about what might have caused it.
    2. If their sleep was low, ask how it affected their mood.
    3. Generate exactly 2 short, specific journaling prompts.
    4. Generate 1 short paragraph (max 3 sentences) summarizing their physiology today in a non-clinical, supportive way.
    
    Respond STRICTLY in the following JSON schema:
    {
        "prompts": ["Prompt 1", "Prompt 2"],
        "summary": "The short paragraph summary."
    }
    """

    user_context = _format_context_for_prompt(today_metrics, anomaly, past_journals)
    
    prompt = f"{system_instruction}\\n\\nDATA CONTEXT:\\n{user_context}"
    
    try:
        # Request JSON mode to ensure the output parses easily
        response = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(response_mime_type="application/json")
        )
        
        result_dict = json.loads(response.text)
        
        return AgentResponse(
            user_id=user_id,
            date=today_metrics.date,
            prompts=result_dict.get("prompts", []),
            daily_summary=result_dict.get("summary", "Gathering insights...")
        )
        
    except Exception as e:
        print(f"Agent Generation Error: {e}")
        # Fallback
        return AgentResponse(
            user_id=user_id,
            date=today_metrics.date,
            prompts=["How are you feeling right now?", "What's on your mind today?"],
            daily_summary="We had trouble connecting to the AI coach, but we're still here to listen."
        )

if __name__ == "__main__":
    # Test the prompt formatting (even without Vertex enabled it hits the fallback)
    uid = "test_user_123"
    
    metrics = DailyMetrics(
        user_id=uid,
        date=date.today(),
        rhr_avg=78.5,
        sleep_duration_hrs=5.2
    )
    
    anom = AnomalyReport(
        user_id=uid,
        date=date.today(),
        is_stress_event=True,
        score=0.8
    )
    
    agent_resp = generate_daily_insights(uid, metrics, anom)
    print("Agent Response:", agent_resp.model_dump_json(indent=2))
