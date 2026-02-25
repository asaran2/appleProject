import Foundation
import Combine

#if os(iOS)
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    
    // Types of data we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    // MARK: - Authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "InsightJournal", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success, error)
            }
        }
    }
    
    // MARK: - Fetch Daily Aggregated Metrics
    /// Fetches the required features for today to send to the backend MVP
    func fetchTodayMetrics(completion: @escaping ([String: Any]?) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        var metricsPayload: [String: Any] = [
            "user_id": "arushi_demo_1", // Hardcoded for MVP
            "date": ISO8601DateFormatter().string(from: startOfDay)
        ]
        
        let dispatchGroup = DispatchGroup()
        
        // 1. Fetch Resting Heart Rate Avg
        dispatchGroup.enter()
        fetchAveragedQuantity(for: .restingHeartRate, predicate: predicate) { avgRHR in
            if let rhr = avgRHR { metricsPayload["rhr_avg"] = rhr }
            dispatchGroup.leave()
        }
        
        // 2. Fetch Sleep Duration (Hrs)
        dispatchGroup.enter()
        fetchSleepDuration(predicate: predicate) { sleepHrs in
            if let hrs = sleepHrs { metricsPayload["sleep_duration_hrs"] = hrs }
            dispatchGroup.leave()
        }
        
        // 3. Fetch HRV (Avg SDNN)
        dispatchGroup.enter()
        fetchAveragedQuantity(for: .heartRateVariabilitySDNN, predicate: predicate) { avgHRV in
            if let hrv = avgHRV { metricsPayload["hrv_rmssd"] = hrv } // Mapping SDNN as proxy for MVP
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(metricsPayload)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchAveragedQuantity(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, completion: @escaping (Double?) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
            guard let result = result, let averageQuantity = result.averageQuantity() else {
                completion(nil)
                return
            }
            
            // Determine expected unit
            let unit: HKUnit = identifier == .heartRateVariabilitySDNN ? HKUnit.secondUnit(with: .milli) : HKUnit.count().unitDivided(by: HKUnit.minute())
            completion(averageQuantity.doubleValue(for: unit))
        }
        healthStore.execute(query)
    }
    
    private func fetchSleepDuration(predicate: NSPredicate, completion: @escaping (Double?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        // Exclude inBed states, only look for ASLEEP states
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            
            guard let categorySamples = samples as? [HKCategorySample] else {
                completion(nil)
                return
            }
            
            var totalSleepSeconds: TimeInterval = 0
            for sample in categorySamples {
                // value == 0 is typically inBed. 1 or higher usually denotes sleep stages.
                if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue || 
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    
                    totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            if totalSleepSeconds > 0 {
                // Convert to hours
                completion(totalSleepSeconds / 3600.0)
            } else {
                completion(nil)
            }
        }
        healthStore.execute(query)
    }
}

#else

// Stub for non-iOS platforms (macOS, visionOS)
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    @Published var isAuthorized: Bool = false
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        completion(false, nil)
    }
    
    func fetchTodayMetrics(completion: @escaping ([String: Any]?) -> Void) {
        completion(nil)
    }
}

#endif
