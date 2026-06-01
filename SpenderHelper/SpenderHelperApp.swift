import SwiftUI
import SwiftData

@main
struct SpenderHelperApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(DataController.sharedModelContainer)
    }
}
