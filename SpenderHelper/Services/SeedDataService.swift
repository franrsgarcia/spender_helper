import Foundation
import SwiftData

enum SeedDataService {
    private static let defaultCategoryNames = ["Food", "Transport", "Shopping", "Bills", "Other"]
    private static let defaultAccountName = "Default"

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        seedCategoriesIfNeeded(context: context)
        seedAccountsIfNeeded(context: context)
        migrateLegacyCategoryRaw(context: context)
        try? context.save()
    }

    private static func seedCategoriesIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard count == 0 else { return }
        for (index, name) in defaultCategoryNames.enumerated() {
            context.insert(Category(name: name, sortOrder: index))
        }
    }

    private static func seedAccountsIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0
        guard count == 0 else { return }
        context.insert(Account(name: defaultAccountName, sortOrder: 0))
    }

    private static func migrateLegacyCategoryRaw(context: ModelContext) {
        guard let expenses = try? context.fetch(FetchDescriptor<Expense>()) else { return }
        guard let categories = try? context.fetch(
            FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        ) else { return }

        let other = categories.first { $0.name == "Other" } ?? categories.last

        for expense in expenses {
            guard expense.category == nil, !expense.categoryRaw.isEmpty else { continue }
            expense.category = categories.first { $0.name == expense.categoryRaw } ?? other
            if expense.category != nil {
                expense.categoryRaw = expense.category!.name
            }
        }
    }
}
