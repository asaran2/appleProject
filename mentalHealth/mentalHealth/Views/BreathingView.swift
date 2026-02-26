import SwiftUI
import Combine

struct BreathingView: View {
    @State private var isInhaling = true
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.auroraBackground.ignoresSafeArea()
            
            VStack(spacing: AppTheme.vSpacing) {
                // Header
                VStack(spacing: 8) {
                    Text(isInhaling ? "Inhale Life" : "Exhale Stress")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.auroraDeepPurple)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .id(isInhaling)
                    
                    Text("Follow the rhythmic pulse")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Breathing Circle
                ZStack {
                    Circle()
                        .fill(AppTheme.auroraTeal.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .scaleEffect(scale * 1.2)
                        .blur(radius: 40)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, AppTheme.auroraTeal.opacity(0.6)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 120
                            )
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                        )
                }
                .ambientGlow(color: AppTheme.auroraTeal, intensity: 0.5)
                
                Spacer()
                
                // Instructions / Tips
                VStack(spacing: 24) {
                    Text(isInhaling ? "Inhale Deeply" : "Exhale Softly")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.auroraDeepPurple)
                        .transition(.opacity)
                        .id(isInhaling)
                    
                    Text("Follow the rhythmic pulse to anchor your awareness in the present moment.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.auroraIndigo.opacity(0.8))
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                    
                    Button(action: { /* Stop Session */ }) {
                        Text("End Session")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(AppTheme.auroraIndigo))
                            .ambientGlow(color: AppTheme.auroraIndigo, intensity: 0.3)
                    }
                }
                .floatingGlassCard()
                .padding(.horizontal, AppTheme.hPadding)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Initial animation state
            withAnimation(.easeInOut(duration: 4)) {
                scale = 1.4
                opacity = 0.9
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 4)) {
                isInhaling.toggle()
                scale = isInhaling ? 1.4 : 1.0
                opacity = isInhaling ? 0.9 : 0.5
            }
        }
    }
}

#Preview {
    BreathingView()
}
