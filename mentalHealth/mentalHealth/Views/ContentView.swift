import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    
    var body: some View {
        Group {
            if viewModel.healthDataSynced {
                DailyCheckInView()
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(InsightViewModel())
}
