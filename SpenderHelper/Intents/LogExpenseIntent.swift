import AppIntents

struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Open Spender Helper to log a purchase.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        AppLaunchState.requestQuickLog()
        await MainActor.run {
            NotificationCenter.default.post(name: .spenderHelperShowQuickLog, object: nil)
        }
        return .result()
    }
}
