import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var onDismiss: (() -> Void)?

    @State private var amountText = ""
    @State private var merchant = ""
    @State private var category: ExpenseCategory = .other
    @State private var notes = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.largeTitle)
                        .monospacedDigit()
                } header: {
                    Text("Amount")
                }

                Section {
                    TextField("Merchant", text: $merchant)
                        .textInputAutocapitalization(.words)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Log Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        close()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save(andContinue: false)
                    }
                    .fontWeight(.semibold)
                    .disabled(parsedAmount == nil)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    save(andContinue: true)
                } label: {
                    Text("Save & Add Another")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .disabled(parsedAmount == nil)
            }
        }
    }

    private var parsedAmount: Decimal? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty, let value = Decimal(string: normalized), value > 0 else {
            return nil
        }
        return value
    }

    private func save(andContinue: Bool) {
        guard let amount = parsedAmount else {
            saveError = "Enter a valid amount greater than zero."
            return
        }
        saveError = nil
        let expense = Expense(
            amount: amount,
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(expense)
        do {
            try modelContext.save()
        } catch {
            saveError = "Could not save: \(error.localizedDescription)"
            return
        }
        if andContinue {
            amountText = ""
            merchant = ""
            notes = ""
            category = .other
        } else {
            close()
        }
    }

    private func close() {
        if let onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}
