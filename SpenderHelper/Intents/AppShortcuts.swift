import AppIntents

struct SpenderHelperShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log expense in \(.applicationName)",
                "Log spending in \(.applicationName)",
                "Add expense in \(.applicationName)",
            ],
            shortTitle: "Log Expense",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: ExportExpensesIntent(),
            phrases: [
                "Export expenses in \(.applicationName)",
                "Export spending in \(.applicationName)",
                "Export CSV in \(.applicationName)",
            ],
            shortTitle: "Export Expenses",
            systemImageName: "square.and.arrow.up"
        )
    }
}
