import SwiftUI

struct OnboardingStep {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    @State private var currentStep = 0
    
    let steps = [
        OnboardingStep(
            title: "Track Your Mood",
            description: "Understand your emotional patterns with AI-driven insights from your heart rate and sleep.",
            icon: "face.smiling.fill",
            color: AppTheme.auroraBlue
        ),
        OnboardingStep(
            title: "Guided Meditation",
            description: "Find your inner peace with sessions tailored to your current physiological state.",
            icon: "leaf.fill",
            color: AppTheme.auroraTeal
        ),
        OnboardingStep(
            title: "Progress Insights",
            description: "See how your mental wellness improves over time with detailed analytics.",
            icon: "chart.line.uptrend.xyaxis",
            color: AppTheme.auroraPink
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.auroraBackground.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") {
                        viewModel.skipOnboarding()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                    .padding(AppTheme.hPadding)
                }
                
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack(spacing: AppTheme.vSpacing) {
                            Spacer()
                            
                            // Illustration
                            ZStack {
                                Circle()
                                    .fill(steps[index].color.opacity(0.15))
                                    .frame(width: 240, height: 240)
                                    .blur(radius: 40)
                                
                                Image(systemName: steps[index].icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(steps[index].color)
                                    .ambientGlow(color: steps[index].color, intensity: 0.4)
                            }
                            
                            VStack(spacing: 16) {
                                Text(steps[index].title)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.auroraDeepPurple)
                                
                                Text(steps[index].description)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppTheme.auroraIndigo.opacity(0.8))
                                    .padding(.horizontal, AppTheme.hPadding + 10)
                                    .lineSpacing(4)
                            }
                            .floatingGlassCard()
                            .padding(.horizontal, AppTheme.hPadding)
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                
                // Action Button
                Button(action: {
                    if currentStep < steps.count - 1 {
                        withAnimation { currentStep += 1 }
                    } else {
                        viewModel.requestPermissions()
                    }
                }) {
                    Text(currentStep == steps.count - 1 ? "Sync Health Data" : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Capsule().fill(AppTheme.auroraIndigo))
                        .padding(.horizontal, AppTheme.hPadding * 2)
                        .padding(.bottom, 40)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom, 10)
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(InsightViewModel())
}
