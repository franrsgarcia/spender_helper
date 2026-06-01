import SwiftUI
import SwiftData

struct ExpenseEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Bindable var expense: Expense

    @State private var amountText: String = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section("Details") {
                    TextField("Merchant", text: $expense.merchant)
                    if categories.isEmpty {
                        Text("Add categories in Settings")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: Binding(
                            get: { expense.category?.id },
                            set: { id in
                                expense.category = categories.first { $0.id == id }
                                if let name = expense.category?.name {
                                    expense.categoryRaw = name
                                }
                            }
                        )) {
                            ForEach(categories) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                    }
                    if accounts.isEmpty {
                        Text("No accounts configured")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Card / Account", selection: Binding(
                            get: { expense.account?.id },
                            set: { id in
                                expense.account = id.flatMap { accountID in
                                    accounts.first { $0.id == accountID }
                                }
                            }
                        )) {
                            Text("None").tag(nil as UUID?)
                            ForEach(accounts) { account in
                                Text(account.name).tag(account.id as UUID?)
                            }
                        }
                    }
                    DatePicker("Date", selection: $expense.date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Notes", text: $expense.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                if let saveError {
                    Section {
                        Text(saveError).foregroundStyle(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                let number = expense.amount as NSDecimalNumber
                amountText = String(format: "%.2f", number.doubleValue)
            }
        }
    }

    private func save() {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized), value > 0 else {
            saveError = "Enter a valid amount greater than zero."
            return
        }
        expense.amount = value
        if let category = expense.category {
            expense.categoryRaw = category.name
        }
        dismiss()
    }
}
