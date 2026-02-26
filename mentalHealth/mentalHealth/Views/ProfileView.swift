import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.auroraBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.vSpacing) {
                        
                        // Header / Avatar
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.auroraSunrise)
                                    .frame(width: 100, height: 100)
                                    .ambientGlow(color: AppTheme.auroraPink, intensity: 0.4)
                                
                                Text("JD")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text("John Doe")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.auroraDeepPurple)
                                
                                Text("Mindfulness Explorer")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                            }
                        }
                        .padding(.top, 40)
                        
                        // Goals Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Wellness Goals")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraDeepPurple)
                                .padding(.horizontal, AppTheme.hPadding)
                            
                            VStack(spacing: 16) {
                                GoalRow(title: "Morning Coherence", progress: 0.8, color: AppTheme.auroraTeal)
                                GoalRow(title: "Journaling Habit", progress: 0.6, color: AppTheme.auroraPink)
                                GoalRow(title: "Deep Sleep Goal", progress: 0.4, color: AppTheme.auroraBlue)
                            }
                            .floatingGlassCard()
                            .padding(.horizontal, AppTheme.hPadding)
                        }
                        
                        // Settings Shortcuts
                        VStack(spacing: 12) {
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: AppTheme.auroraBlue)
                            SettingsRow(icon: "lock.fill", title: "Privacy & Data", color: AppTheme.auroraTeal)
                            SettingsRow(icon: "gearshape.fill", title: "App Settings", color: AppTheme.auroraIndigo)
                        }
                        .padding(.horizontal, AppTheme.hPadding)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarHidden(true)
        }
    }
}

struct GoalRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.auroraDeepPurple)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.auroraIndigo)
            }
            
            ProgressView(value: progress)
                .accentColor(color)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color))
            
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.auroraDeepPurple)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.auroraIndigo.opacity(0.3))
        }
        .padding()
        .floatingGlassCard()
    }
}

#Preview {
    ProfileView()
        .environmentObject(InsightViewModel())
}
