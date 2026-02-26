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
    
    private let backendURL = "http://127.0.0.1:8000/api/v1" // Use your Mac's local IP address to allow connectivity between devices
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
        self.isLoading = true
        
        hkManager.fetchTodayMetrics { metricsPayload in
            guard let payload = metricsPayload else {
                DispatchQueue.main.async {
                    self.errorMessage = "Not enough health data collected today to analyze."
                    self.isLoading = false
                }
                return
            }
            
            // Format for the `/sync-health` endpoint
            let requestBody: [String: Any] = [
                "user_id": self.userId,
                "data_source": "apple_watch_healthkit",
                "payload": payload // We send the JSON object dict instead of the massive XML string now!
            ]
            
            self.postToBackend(endpoint: "/sync-health", body: requestBody) { success in
                DispatchQueue.main.async {
                    if success {
                        self.healthDataSynced = true
                        // 3. Immediately fetch the AI prompts now that data is synced
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "AI Server Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let prompts = json["prompts"] as? [String] {
                            self.dailyPrompts = prompts
                        }
                        if let summary = json["daily_summary"] as? String {
                            self.dailySummary = summary
                        }
                        if let date = json["date"] as? String {
                            self.dataDate = date
                        }
                        
                        let formatter = DateFormatter()
                        formatter.timeStyle = .short
                        self.lastSyncedTime = formatter.string(from: Date())
                    }
                } catch {
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
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}
