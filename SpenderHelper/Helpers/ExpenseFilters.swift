import Foundation

struct ExpenseFilters: Equatable {
    var period: TimePeriodFilter = .all
    var customStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    var customEnd: Date = Date()
    var selectedCategoryIDs: Set<UUID> = []
    var selectedAccountIDs: Set<UUID> = []

    var hasActiveFilters: Bool {
        period != .all || !selectedCategoryIDs.isEmpty || !selectedAccountIDs.isEmpty
    }

    func apply(to expenses: [Expense], calendar: Calendar = .current) -> [Expense] {
        expenses.filter { expense in
            matchesPeriod(expense, calendar: calendar)
                && matchesCategory(expense)
                && matchesAccount(expense)
        }
    }

    private func matchesPeriod(_ expense: Expense, calendar: Calendar) -> Bool {
        guard let interval = period.dateInterval(
            customStart: customStart,
            customEnd: customEnd,
            calendar: calendar
        ) else {
            return true
        }
        return interval.contains(expense.date)
    }

    private func matchesCategory(_ expense: Expense) -> Bool {
        guard !selectedCategoryIDs.isEmpty else { return true }
        guard let categoryID = expense.category?.id else { return false }
        return selectedCategoryIDs.contains(categoryID)
    }

    private func matchesAccount(_ expense: Expense) -> Bool {
        guard !selectedAccountIDs.isEmpty else { return true }
        guard let accountID = expense.account?.id else { return false }
        return selectedAccountIDs.contains(accountID)
    }
}
