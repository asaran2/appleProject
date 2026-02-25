import SwiftUI

struct DailyCheckInView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    @State private var moodScore: Double = 5.0
    @State private var journalText: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    if viewModel.isLoading {
                        ProgressView("Analyzing your physiology...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 50)
                    } else {
                        // AI Summary Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Daily Insight")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let syncTime = viewModel.lastSyncedTime {
                                    Text("Updated \(syncTime)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let dataDate = viewModel.dataDate {
                                Text("Showing metrics for \(dataDate)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            
                            Text(viewModel.dailySummary)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        Divider()
                        
                        // Reflection Prompts
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Reflection Prompts")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(viewModel.dailyPrompts, id: \.self) { prompt in
                                Text("• \(prompt)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Divider()
                        
                        // Journal Entry
                        VStack(alignment: .leading, spacing: 15) {
                            Text("How are you feeling overall?")
                                .font(.headline)
                            
                            HStack {
                                Text("Low")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: $moodScore, in: 1...10, step: 1)
                                Text("High")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Mood Score: \(Int(moodScore))/10")
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            TextEditor(text: $journalText)
                                .frame(height: 150)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            
                            Button(action: {
                                viewModel.submitJournal(text: journalText, moodScore: Int(moodScore))
                                // Very basic clear for MVP
                                journalText = ""
                            }) {
                                Text("Save Journal")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(journalText.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(12)
                            }
                            .disabled(journalText.isEmpty)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today's Check-In")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.syncHealthData()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.headline)
                    }
                }
            }
        }
    }
}

#Preview {
    DailyCheckInView()
        .environmentObject(InsightViewModel())
}
