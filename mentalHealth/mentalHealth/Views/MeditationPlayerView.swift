import SwiftUI

struct MeditationPlayerView: View {
    @State private var isPlaying = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var orbScale: CGFloat = 1.0
    @State private var orbOpacity: Double = 0.6
    
    let totalTime: TimeInterval = 300 // 5 minutes
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.auroraBackground.ignoresSafeArea()
            
            // Atmospheric Particles
            ZStack {
                ForEach(0..<12) { i in
                    Circle()
                        .fill(AppTheme.auroraBlue.opacity(0.2))
                        .frame(width: CGFloat.random(in: 4...10))
                        .offset(x: CGFloat.random(in: -200...200), y: CGFloat.random(in: -400...400))
                        .blur(radius: 2)
                }
            }
            .opacity(isPlaying ? 1 : 0.3)
            
            VStack(spacing: AppTheme.vSpacing) {
                HStack {
                    Spacer()
                    Button(action: { /* Dismiss */ }) {
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .foregroundColor(AppTheme.auroraIndigo)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.5)))
                    }
                    .padding(AppTheme.hPadding)
                }
                
                Spacer()
                
                // Breathing Orb (Bright on Light Background)
                ZStack {
                    Circle()
                        .fill(AppTheme.auroraTeal.opacity(0.2))
                        .frame(width: 250, height: 250)
                        .blur(radius: 40)
                        .scaleEffect(orbScale * 1.2)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, AppTheme.auroraBlue.opacity(0.8)],
                                center: .center,
                                startRadius: 2,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(orbScale)
                        .opacity(orbOpacity)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                .ambientGlow(color: AppTheme.auroraTeal, intensity: 0.4)
                
                Spacer()
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Morning Coherence")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.auroraDeepPurple)
                        
                        Text("Guided by the Light")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                            .tracking(1)
                    }
                    
                    // Controls
                    HStack(spacing: 40) {
                        Button(action: {}) {
                            Image(systemName: "gobackward.15")
                                .font(.title2)
                                .foregroundColor(AppTheme.auroraIndigo.opacity(0.7))
                        }
                        
                        Button(action: { isPlaying.toggle() }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .padding(24)
                                .background(Circle().fill(AppTheme.auroraIndigo))
                        }
                        .ambientGlow(color: AppTheme.auroraIndigo, intensity: 0.3)
                        
                        Button(action: {}) {
                            Image(systemName: "goforward.15")
                                .font(.title2)
                                .foregroundColor(AppTheme.auroraIndigo.opacity(0.7))
                        }
                    }
                    
                    // Progress
                    VStack(spacing: 12) {
                        Capsule()
                            .fill(Color.black.opacity(0.05))
                            .frame(height: 6)
                            .overlay(
                                GeometryReader { geo in
                                    Capsule()
                                        .fill(AppTheme.auroraBlue)
                                        .frame(width: geo.size.width * 0.3)
                                }
                            )
                            .padding(.horizontal, AppTheme.hPadding * 2)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startBreathingAnimation()
        }
    }
    
    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            orbScale = 1.2
            orbOpacity = 0.9
        }
    }
}

#Preview {
    MeditationPlayerView()
}
