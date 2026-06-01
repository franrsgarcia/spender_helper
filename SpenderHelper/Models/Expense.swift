import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var date: Date
    var amount: Decimal
    var currency: String
    var merchant: String
    var notes: String
    var createdAt: Date

    /// Legacy field for migration from fixed categories; cleared after migration.
    var categoryRaw: String

    /// Empty for manual entries; `"bank"` for rows imported from a bank CSV.
    var importSource: String
    /// Stable key for bank import deduplication and sync.
    var importKey: String

    var category: Category?
    var account: Account?

    var categoryDisplayName: String {
        category?.name ?? (categoryRaw.isEmpty ? "Uncategorized" : categoryRaw)
    }

    var accountDisplayName: String {
        account?.name ?? ""
    }

    var isBankImported: Bool {
        importSource == "bank"
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Decimal,
        currency: String = Locale.current.currency?.identifier ?? "USD",
        merchant: String = "",
        category: Category? = nil,
        account: Account? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        categoryRaw: String = "",
        importSource: String = "",
        importKey: String = ""
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.category = category
        self.account = account
        self.notes = notes
        self.createdAt = createdAt
        self.categoryRaw = categoryRaw
        self.importSource = importSource
        self.importKey = importKey
        if category != nil {
            self.categoryRaw = category!.name
        }
    }
}
