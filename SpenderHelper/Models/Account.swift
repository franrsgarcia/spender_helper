import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Expense.account)
    var expenses: [Expense]?

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }
}
