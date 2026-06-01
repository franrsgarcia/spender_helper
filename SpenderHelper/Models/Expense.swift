import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var date: Date
    var amount: Decimal
    var currency: String
    var merchant: String
    var categoryRaw: String
    var notes: String
    var createdAt: Date

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Decimal,
        currency: String = Locale.current.currency?.identifier ?? "USD",
        merchant: String = "",
        category: ExpenseCategory = .other,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }
}
