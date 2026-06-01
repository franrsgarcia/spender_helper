import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.merchant.isEmpty ? "Expense" : expense.merchant)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(expense.categoryDisplayName)
                    if !expense.accountDisplayName.isEmpty {
                        Text("·")
                        Text(expense.accountDisplayName)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Text(Self.dateFormatter.string(from: expense.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formattedAmount)
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    private var formattedAmount: String {
        let number = expense.amount as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = expense.currency
        return formatter.string(from: number) ?? "\(number) \(expense.currency)"
    }
}
