import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case other = "Other"

    var id: String { rawValue }
}
