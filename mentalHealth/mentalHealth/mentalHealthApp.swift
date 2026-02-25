import SwiftUI

@main
struct mentalHealthApp: App {
    @StateObject private var viewModel = InsightViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
