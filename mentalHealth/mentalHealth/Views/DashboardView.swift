import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case breathing, meditation
        var id: Int { hashValue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.auroraBackground.ignoresSafeArea()
                
                // Softer Ambient Glows
                VStack {
                    HStack {
                        Circle()
                            .fill(AppTheme.auroraPink.opacity(0.15))
                            .frame(width: 400)
                            .blur(radius: 80)
                            .offset(x: -150, y: -100)
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.vSpacing) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Home")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                                .tracking(2)
                                .textCase(.uppercase)
                            
                            Text("Breathe in the calm.")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                        }
                        .padding(.horizontal, AppTheme.hPadding)
                        .padding(.top, 20)
                        
                        // Mood Check-in Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.auroraPink)
                                Text("Your Emotional Sky")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.auroraDeepPurple)
                            }
                            
                            Text("How does your inner world feel today?")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.auroraIndigo.opacity(0.8))
                                .lineSpacing(4)
                            
                            Button(action: {
                                // Action handled in DailyCheckIn tab
                            }) {
                                Text("Check-in")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 28)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.auroraIndigo)
                                    )
                                    .ambientGlow(color: AppTheme.auroraIndigo, intensity: 0.3)
                            }
                        }
                        .floatingGlassCard()
                        .padding(.horizontal, AppTheme.hPadding)
                        
                        // Shortcuts Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Ethereal Moments")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                                .padding(.horizontal, AppTheme.hPadding)
                            
                            HStack(spacing: AppTheme.cardSpacing) {
                                AuroraShortcutCard(
                                    title: "Breathe",
                                    icon: "wind",
                                    glowColor: AppTheme.auroraTeal
                                )
                                .onTapGesture { activeSheet = .breathing }
                                
                                AuroraShortcutCard(
                                    title: "Meditate",
                                    icon: "leaf.fill",
                                    glowColor: AppTheme.auroraPink
                                )
                                .onTapGesture { activeSheet = .meditation }
                            }
                            .padding(.horizontal, AppTheme.hPadding)
                        }
                        
                        // Progress Streak
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Mindfulness Streak")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.auroraDeepPurple)
                                Spacer()
                                Label("4 Days", systemImage: "flame.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            
                            HStack(spacing: (UIScreen.main.bounds.width - (AppTheme.hPadding * 2) - 40 - (35 * 7)) / 6) {
                                ForEach(0..<7) { day in
                                    Circle()
                                        .fill(day < 4 ? AppTheme.auroraBlue : Color.black.opacity(0.05))
                                        .frame(width: 35, height: 35)
                                        .overlay(
                                            Text(["M", "T", "W", "T", "F", "S", "S"][day])
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(day < 4 ? .white : AppTheme.auroraIndigo.opacity(0.3))
                                        )
                                }
                            }
                        }
                        .floatingGlassCard()
                        .padding(.horizontal, AppTheme.hPadding)
                        
                        Spacer(minLength: 80)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { item in
                switch item {
                case .breathing: BreathingView()
                case .meditation: MeditationPlayerView()
                }
            }
        }
    }
}

struct AuroraShortcutCard: View {
    let title: String
    let icon: String
    let glowColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(AppTheme.auroraIndigo)
                .ambientGlow(color: glowColor, intensity: 0.4)
            
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.auroraDeepPurple)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .floatingGlassCard()
    }
}


#Preview {
    DashboardView()
        .environmentObject(InsightViewModel())
}
