import SwiftUI

struct RootView: View {
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
                if AppLaunchState.shouldShowQuickLog {
                    showQuickLog = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .spenderHelperShowQuickLog)) { _ in
                showQuickLog = true
            }
    }
}
