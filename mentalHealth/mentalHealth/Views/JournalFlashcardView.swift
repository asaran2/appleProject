import SwiftUI

struct JournalFlashcardView: View {
    @EnvironmentObject var viewModel: InsightViewModel
    @State private var currentIndex = 0
    @State private var answer: String = ""
    @State private var answers: [Int: String] = [:]
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.auroraBackground.ignoresSafeArea()
            
            VStack(spacing: AppTheme.vSpacing) {
                if viewModel.dailyPrompts.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 80))
                            .foregroundColor(AppTheme.auroraIndigo.opacity(0.4))
                            .ambientGlow(color: AppTheme.auroraPink, intensity: 0.3)
                        
                        Text("Ready to reflect?")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.auroraDeepPurple)
                        
                        Button("Prepare Your Journal") {
                            viewModel.syncHealthData()
                        }
                        .buttonStyle(.bordered)
                        .tint(AppTheme.auroraDeepPurple)
                    }
                } else {
                    // Header
                    HStack {
                        Text("Day \(Date().formatted(.dateTime.day().month()))")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                        Spacer()
                        Text("\(currentIndex + 1) / \(viewModel.dailyPrompts.count)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.auroraIndigo.opacity(0.6))
                    }
                    .padding(.horizontal, AppTheme.hPadding)
                    .padding(.top, 20)
                    
                    // Flashcard
                    ZStack {
                        VStack(spacing: 24) {
                            Text(viewModel.dailyPrompts[currentIndex])
                                .font(.system(size: 22, weight: .medium, design: .serif))
                                .italic()
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppTheme.auroraDeepPurple)
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
                            
                            // Writing Area
                            ZStack(alignment: .topLeading) {
                                if answer.isEmpty {
                                    Text("Begin writing...")
                                        .font(.system(size: 18, weight: .light, design: .serif))
                                        .foregroundColor(AppTheme.auroraIndigo.opacity(0.3))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                
                                TextEditor(text: $answer)
                                    .font(.system(size: 18, weight: .light, design: .serif))
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .foregroundColor(AppTheme.auroraIndigo)
                            }
                            .frame(height: 180)
                            .padding(.horizontal, 24)
                            
                            Spacer()
                            
                            // Navigation Button
                            HStack {
                                Spacer()
                                Button(action: {
                                    handleNext()
                                }) {
                                    HStack(spacing: 8) {
                                        Text(currentIndex == viewModel.dailyPrompts.count - 1 ? "Complete" : "Continue")
                                        Image(systemName: "arrow.right")
                                    }
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 24)
                                    .background(Capsule().fill(AppTheme.auroraIndigo))
                                    .ambientGlow(color: AppTheme.auroraIndigo, intensity: 0.3)
                                }
                            }
                            .padding(.bottom, 30)
                            .padding(.horizontal, 24)
                        }
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .floatingGlassCard()
                        .padding(.horizontal, AppTheme.hPadding)
                        .id(currentIndex)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                    
                    // Back Navigation
                    if currentIndex > 0 {
                        Button(action: {
                            withAnimation(.spring()) {
                                answers[currentIndex] = answer
                                currentIndex -= 1
                                answer = answers[currentIndex] ?? ""
                            }
                        }) {
                            Text("Previous Prompt")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.auroraIndigo.opacity(0.5))
                        }
                        .padding(.bottom, 20)
                    } else {
                        Spacer().frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func handleNext() {
        withAnimation(.spring()) {
            answers[currentIndex] = answer
            if currentIndex < viewModel.dailyPrompts.count - 1 {
                currentIndex += 1
                answer = answers[currentIndex] ?? ""
            } else {
                // Final Submission
                var combined = ""
                for (index, text) in answers {
                    combined += "Q: \(viewModel.dailyPrompts[index])\nA: \(text)\n\n"
                }
                viewModel.submitJournal(text: combined, moodScore: 5)
            }
        }
    }
}

#Preview {
    let vm = InsightViewModel()
    vm.dailyPrompts = ["How was your sleep?", "What made you smile today?", "How do you feel about tomorrow?"]
    return JournalFlashcardView().environmentObject(vm)
}
