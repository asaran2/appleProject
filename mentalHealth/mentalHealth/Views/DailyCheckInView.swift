import SwiftUI

struct DailyCheckInView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    @State private var showingJournal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.auroraBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.vSpacing) {
                        
                        // Mood Tracker Section
                        MoodTrackerView()
                            .frame(height: 380)
                        
                        // Insight Summary Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Physiology Insight", systemImage: "sparkles")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.auroraPink)
                                Spacer()
                            }
                            
                            Text(viewModel.dailySummary)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                                .lineSpacing(4)
                        }
                        .floatingGlassCard()
                        .padding(.horizontal, AppTheme.hPadding)
                        
                        // Journaling Entry Point
                        VStack(spacing: 24) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.auroraPink)
                            
                            Text("Ready for your reflection?")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                            
                            Button(action: {
                                showingJournal = true
                            }) {
                                Text("Start Journaling")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Capsule().fill(AppTheme.auroraIndigo))
                                    .ambientGlow(color: AppTheme.auroraIndigo, intensity: 0.3)
                            }
                        }
                        .floatingGlassCard()
                        .padding(.horizontal, AppTheme.hPadding)
                        
                        Spacer(minLength: 80)
                    }
                }
            }
            .navigationTitle("Today's Check-In")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingJournal) {
                JournalFlashcardView()
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    DailyCheckInView()
        .environmentObject(InsightViewModel())
}
