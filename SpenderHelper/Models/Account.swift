import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var sortOrder: Int

    /// Bank account number from imported statements (e.g. 0673059858900).
    var bankAccountNumber: String
    var accountingBalance: Decimal?
    var availableBalance: Decimal?
    var balanceCurrency: String
    var statementPeriodStart: Date?
    var statementPeriodEnd: Date?
    var lastImportedAt: Date?

    @Relationship(deleteRule: .nullify, inverse: \Expense.account)
    var expenses: [Expense]?

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0,
        bankAccountNumber: String = "",
        accountingBalance: Decimal? = nil,
        availableBalance: Decimal? = nil,
        balanceCurrency: String = "EUR",
        statementPeriodStart: Date? = nil,
        statementPeriodEnd: Date? = nil,
        lastImportedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.bankAccountNumber = bankAccountNumber
        self.accountingBalance = accountingBalance
        self.availableBalance = availableBalance
        self.balanceCurrency = balanceCurrency
        self.statementPeriodStart = statementPeriodStart
        self.statementPeriodEnd = statementPeriodEnd
        self.lastImportedAt = lastImportedAt
    }
}
