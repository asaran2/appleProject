import SwiftUI

struct ProgressAnalyticsView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.auroraBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.vSpacing) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Evolution")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                                .tracking(2)
                                .textCase(.uppercase)
                            
                            Text("Growth Insights")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                        }
                        .padding(.horizontal, AppTheme.hPadding)
                        .padding(.top, 20)
                        
                        // Main Mood Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Emotional Highs & Lows")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                            
                            // Simple Chart Mockup
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.auroraSunrise.opacity(0.2))
                                .frame(height: 180)
                                .overlay(
                                    HStack(alignment: .bottom, spacing: 15) {
                                        ForEach(0..<7) { i in
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(i == 4 ? AppTheme.auroraPink : AppTheme.auroraBlue.opacity(0.6))
                                                .frame(width: 25, height: CGFloat.random(in: 40...140))
                                        }
                                    }
                                    .padding(.bottom, 20)
                                )
                        }
                        .floatingGlassCard()
                        .padding(.horizontal, AppTheme.hPadding)
                        
                        // Insight Orbs Grid
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Current State")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                                .padding(.horizontal, AppTheme.hPadding)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.cardSpacing) {
                                InsightOrb(title: "Calmness", percentage: "84%", color: AppTheme.auroraTeal)
                                InsightOrb(title: "Vibrancy", percentage: "62%", color: AppTheme.auroraPink)
                                InsightOrb(title: "Clarity", percentage: "78%", color: AppTheme.auroraBlue)
                                InsightOrb(title: "Resilience", percentage: "91%", color: AppTheme.auroraIndigo)
                            }
                            .padding(.horizontal, AppTheme.hPadding)
                        }
                        
                        // Deep AI Insight Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppTheme.auroraPink)
                                Text("AI Perspective")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.auroraDeepPurple)
                            }
                            
                            Text("Your physiology suggests a high readiness for creative work today. Morning coherence was 15% higher than your weekday average.")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.auroraIndigo.opacity(0.8))
                                .lineSpacing(4)
                        }
                        .floatingGlassCard()
                        .padding(.horizontal, AppTheme.hPadding)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct InsightOrb: View {
    let title: String
    let percentage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text(percentage)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.auroraDeepPurple)
            }
            .ambientGlow(color: color, intensity: 0.3)
            
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.auroraIndigo)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .floatingGlassCard()
    }
}
