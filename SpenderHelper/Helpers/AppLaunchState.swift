import Foundation

enum AppLaunchState {
    private static let quickLogKey = "shouldShowQuickLog"

    static var shouldShowQuickLog: Bool {
        get { UserDefaults.standard.bool(forKey: quickLogKey) }
        set { UserDefaults.standard.set(newValue, forKey: quickLogKey) }
    }

    static func requestQuickLog() {
        shouldShowQuickLog = true
    }

    static func clearQuickLogRequest() {
        shouldShowQuickLog = false
    }
}
