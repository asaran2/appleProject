import SwiftUI

struct MoodTrackerView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    @State private var selectedMood: Int?
    
    let moods = [
        ("Very Low", "😔", AppTheme.auroraBlue),
        ("Low", "🙁", AppTheme.auroraTeal),
        ("Neutral", "😐", AppTheme.auroraPink),
        ("Good", "🙂", AppTheme.auroraBlue),
        ("Excellent", "🌟", AppTheme.auroraPink)
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.auroraBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: AppTheme.vSpacing) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mood selection")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                        .tracking(2)
                        .textCase(.uppercase)
                    
                    Text("How are you feeling?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.auroraDeepPurple)
                }
                .padding(.horizontal, AppTheme.hPadding)
                .padding(.top, 20)
                
                // Floating Mood Orbs
                HStack(spacing: 0) {
                    ForEach(0..<moods.count, id: \.self) { index in
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(moods[index].2.opacity(selectedMood == index ? 0.3 : 0.1))
                                    .frame(width: 60, height: 60)
                                    .blur(radius: selectedMood == index ? 0 : 5)
                                
                                Text(moods[index].1)
                                    .font(.system(size: 32))
                                    .scaleEffect(selectedMood == index ? 1.3 : 1.0)
                            }
                            .ambientGlow(color: moods[index].2, intensity: selectedMood == index ? 0.4 : 0)
                            
                            Text(moods[index].0)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(selectedMood == index ? AppTheme.auroraDeepPurple : AppTheme.auroraIndigo.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedMood = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .floatingGlassCard()
                .padding(.horizontal, AppTheme.hPadding)
                
                // Mood History Mockup
                VStack(alignment: .leading, spacing: 20) {
                    Text("Emotional Spectrum")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.auroraDeepPurple)
                    
                    // Glowing Chart Mockup
                    HStack(alignment: .bottom, spacing: 14) {
                        ForEach(0..<7) { i in
                            VStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.auroraBlue.opacity(0.6), AppTheme.auroraPink.opacity(0.6)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(width: 25, height: CGFloat([30, 60, 45, 80, 100, 70, 90][i]))
                                    .ambientGlow(color: AppTheme.auroraBlue, intensity: 0.2)
                                
                                Text(["M", "T", "W", "T", "F", "S", "S"][i])
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.auroraIndigo.opacity(0.4))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, AppTheme.hPadding)
                .padding(.vertical, 20)
                .floatingGlassCard()
                .padding(.horizontal, AppTheme.hPadding)
                
                Spacer()
            }
        }
    }
}

#Preview {
    MoodTrackerView()
        .environmentObject(InsightViewModel())
}
