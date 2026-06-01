import SwiftUI

struct ExpenseEditView: View {
    @Environment(\.dismiss) private var dismiss
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
                    Picker("Category", selection: Binding(
                        get: { expense.category },
                        set: { expense.category = $0 }
                    )) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
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
        dismiss()
    }
}
