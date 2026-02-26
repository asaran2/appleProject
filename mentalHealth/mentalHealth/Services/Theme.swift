import SwiftUI

struct AppTheme {
    // Light Aurora Color Palette (Warm & Airy)
    static let warmWhite = Color(hex: "FDFCF9")
    static let softCream = Color(hex: "F9F7F2")
    static let auroraDeepPurple = Color(hex: "4A3C6B") // High contrast text
    static let auroraTeal = Color(hue: 0.5, saturation: 0.4, brightness: 0.8)
    static let auroraPink = Color(hex: "FFB7C5")
    static let auroraBlue = Color(hex: "AEC6CF")
    static let auroraIndigo = Color(hex: "5D5B8D")
    
    // Spacing Constants
    static let hPadding: CGFloat = 24
    static let vSpacing: CGFloat = 32
    static let cardSpacing: CGFloat = 20
    
    // Light Ethereal Gradients
    static let auroraBackground = LinearGradient(
        colors: [softCream, Color(hex: "F0F4F8"), softCream],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let auroraSunrise = LinearGradient(
        colors: [auroraPink.opacity(0.3), auroraBlue.opacity(0.3)],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
    
    static let auroraMist = LinearGradient(
        colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct FloatingGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                ZStack {
                    BlurView(style: .systemThinMaterialLight)
                        .opacity(0.8)
                    Color.white.opacity(0.4)
                }
            )
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct AmbientGlow: ViewModifier {
    var color: Color
    var intensity: Double = 0.2
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity), radius: 15, x: 0, y: 0)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

extension View {
    func floatingGlassCard() -> some View {
        self.modifier(FloatingGlassCard())
    }
    
    func ambientGlow(color: Color, intensity: Double = 0.2) -> some View {
        self.modifier(AmbientGlow(color: color, intensity: intensity))
    }
    
    // Legacy support
    func glassmorphicCard() -> some View {
        self.floatingGlassCard()
    }
    
    func glow(color: Color = .white, radius: CGFloat = 10) -> some View {
        self.ambientGlow(color: color, intensity: 0.3)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
