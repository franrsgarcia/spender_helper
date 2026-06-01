import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showQuickLog = AppLaunchState.shouldShowQuickLog

    var body: some View {
        ContentView()
            .fullScreenCover(isPresented: $showQuickLog, onDismiss: {
                AppLaunchState.clearQuickLogRequest()
            }) {
                QuickLogView(onDismiss: {
                    showQuickLog = false
                    AppLaunchState.clearQuickLogRequest()
                })
            }
            .onAppear {
                SeedDataService.seedIfNeeded(context: modelContext)
                if AppLaunchState.shouldShowQuickLog {
                    showQuickLog = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .spenderHelperShowQuickLog)) { _ in
                showQuickLog = true
            }
    }
}
