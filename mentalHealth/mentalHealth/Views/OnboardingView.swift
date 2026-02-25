import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.pink)
            
            Text("Insight Journal")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Connect your Apple Watch to get personalized, AI-driven journaling prompts based on your heart rate and sleep patterns.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                viewModel.requestPermissions()
            }) {
                Text("Sync Health Data")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(InsightViewModel())
}
