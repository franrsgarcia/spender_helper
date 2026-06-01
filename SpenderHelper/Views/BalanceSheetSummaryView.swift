import SwiftUI
import SwiftData

struct BalanceSheetSummaryView: View {
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    private var accountsWithBalance: [Account] {
        accounts.filter { $0.accountingBalance != nil || $0.availableBalance != nil }
    }

    var body: some View {
        if !accountsWithBalance.isEmpty {
            Section {
                ForEach(accountsWithBalance) { account in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(account.name)
                            .font(.headline)
                        if let accounting = account.accountingBalance {
                            balanceRow("Accounting balance", accounting, currency: account.balanceCurrency)
                        }
                        if let available = account.availableBalance {
                            balanceRow("Available balance", available, currency: account.balanceCurrency)
                        }
                        if let start = account.statementPeriodStart, let end = account.statementPeriodEnd {
                            Text(statementPeriod(start: start, end: end))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let imported = account.lastImportedAt {
                            Text("Imported \(imported.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Balance Sheet")
            }
        }
    }

    private func balanceRow(_ label: String, _ amount: Decimal, currency: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatCurrency(amount, currency: currency))
                .monospacedDigit()
        }
        .font(.subheadline)
    }

    private func formatCurrency(_ amount: Decimal, currency: String) -> String {
        let number = amount as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: number) ?? "\(number) \(currency)"
    }

    private func statementPeriod(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "dd-MM-yyyy"
        return "Period: \(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
}
