import Foundation
import Combine
import SwiftUI

class InsightViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var healthDataSynced: Bool = false
    @Published var dailyPrompts: [String] = []
    @Published var dailySummary: String = "No insights available yet."
    @Published var errorMessage: String? = nil
    @Published var lastSyncedTime: String? = nil
    @Published var dataDate: String? = nil
    
    // private let backendURL = "http://127.0.0.1:8000/api/v1" // Use your Mac's local IP address to allow connectivity between devices
    private let backendURL = "https://f85801e7bb6a2687-68-181-17-181.serveousercontent.com/api/v1" // Use your Mac's local IP address to allow connectivity between devices
    
    private let userId = "arushi_demo_1"
    
    let hkManager = HealthKitManager.shared
    
    // MARK: - 1. Request Health Permissions
    func requestPermissions() {
        hkManager.requestAuthorization { success, error in
            if !success {
                self.errorMessage = error?.localizedDescription ?? "Failed to authorize HealthKit."
            } else {
                // If authorized, trigger the sync
                self.syncHealthData()
            }
        }
    }
    
    // MARK: - 2. Fetch from Watch and Sync to Backend
    func syncHealthData() {
        print("--- SYNC HEALTH DATA TRIGGERED ---")
        self.isLoading = true
        
        hkManager.fetchTodayMetrics { metricsPayload in
            print("--- FETCH TODAY METRICS COMPLETED ---")
            let payload: [String: Any]
            
            if let fetchedPayload = metricsPayload {
                payload = fetchedPayload
            } else {
                print("No data to retrieve")
                payload = [
                    "date": ISO8601DateFormatter().string(from: Date()),
                    "rhr_avg": 65,
                    "hrv_rmssd": 40,
                    "respiratory_rate_avg": 15,
                    "sleep_duration_hrs": 8
                ]
            }
            
            // Format for the `/sync-health` endpoint
            let requestBody: [String: Any] = [
                "user_id": self.userId,
                "data_source": "apple_watch_healthkit",
                "payload": payload // We send the JSON object dict instead of the massive XML string now!
            ]
            
            print("--- INITIATING /sync-health REQUEST ---")
            self.postToBackend(endpoint: "/sync-health", body: requestBody) { success in
                print("--- /sync-health RESPONSE RECEIVED: success=\(success) ---")
                DispatchQueue.main.async {
                    if success {
                        self.healthDataSynced = true
                        print("--- IMMEDIATELY FETCHING AI PROMPTS ---")
                        self.fetchDailyCheckIn()
                    } else {
                        self.errorMessage = "Failed to sync health data to the AI engine."
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Fetch AI Prompts
    func fetchDailyCheckIn() {
        guard let url = URL(string: "\(backendURL)/daily-checkin?user_id=\(userId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "Bypass-Tunnel-Reminder")
        request.setValue("close", forHTTPHeaderField: "Connection")
        
        print("--- SENDING GET TO \(url.absoluteString) ---")
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("--- DAILY CHECKIN RESPONSE RECEIVED ---")
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("--- DAILY CHECK IN ERROR: \(error.localizedDescription) ---")
                    self.errorMessage = "AI Server Error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("--- DAILY CHECK IN HTTP STATUS: \(httpResponse.statusCode) ---")
                }
                
                guard let data = data else {
                    print("--- NO DATA RETURNED ---")
                    return 
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("--- RAW JSON RECEIVED: \(json) ---")
                        if let prompts = json["prompts"] as? [String] {
                            self.dailyPrompts = prompts
                        }
                        if let summary = json["daily_summary"] as? String {
                            self.dailySummary = summary
                        }
                        if let dateStr = json["date"] as? String {
                            self.dataDate = dateStr
                        }
                        
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        self.lastSyncedTime = formatter.string(from: Date())
                    } else {
                        print("--- JSON WAS NOT A DICTIONARY ---")
                    }
                } catch {
                    print("--- JSON PARSING ERROR: \(error.localizedDescription) ---")
                    if let strData = String(data: data, encoding: .utf8) {
                        print("--- RAW DATA: \(strData) ---")
                    }
                    self.errorMessage = "Failed to parse AI response."
                }
            }
        }.resume()
    }
    
    // MARK: - 4. Submit Journal Entry
    func submitJournal(text: String, moodScore: Int) {
        let requestBody: [String: Any] = [
            "user_id": userId,
            "date": ISO8601DateFormatter().string(from: Date()),
            "mood_score": moodScore,
            "text_content": text
        ]
        
        postToBackend(endpoint: "/journal", body: requestBody) { success in
            // Handle success/failure UI changes if necessary
            print("Journal Submitted: \(success)")
        }
    }
    
    // MARK: - Networking Helper
    private func postToBackend(endpoint: String, body: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: backendURL + endpoint) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "Bypass-Tunnel-Reminder")
        request.setValue("close", forHTTPHeaderField: "Connection")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false)
            return
        }
        
        print("--- SENDING POST to \(url.absoluteString) ---")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("--- NETWORK ERROR \(endpoint): \(error.localizedDescription) ---")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("--- HTTP STATUS \(endpoint): \(httpResponse.statusCode) ---")
                if httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    print("--- RESPONSE BODY: \(String(data: data ?? Data(), encoding: .utf8) ?? "NONE") ---")
                    completion(false)
                }
            } else {
                print("--- NO HTTP RESPONSE ---")
                completion(false)
            }
        }.resume()
    }
}
