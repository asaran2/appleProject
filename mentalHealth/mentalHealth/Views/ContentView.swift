import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    @State private var selection = 0
    
    var body: some View {
        Group {
            if viewModel.healthDataSynced {
                TabView(selection: $selection) {
                    DashboardView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    DailyCheckInView()
                        .tabItem {
                            Label("Journal", systemImage: "book.fill")
                        }
                        .tag(1)
                    
                    ProgressAnalyticsView()
                        .tabItem {
                            Label("Insights", systemImage: "chart.bar.fill")
                        }
                        .tag(2)
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                        .tag(3)
                }
                .accentColor(AppTheme.auroraPink)
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
