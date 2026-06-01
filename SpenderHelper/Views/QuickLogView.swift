import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    var onDismiss: (() -> Void)?

    @State private var amountText = ""
    @State private var expenseDate = Date()
    @State private var merchant = ""
    @State private var selectedCategoryID: UUID?
    @State private var selectedAccountID: UUID?
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
                    DatePicker("Date & Time", selection: $expenseDate, displayedComponents: [.date, .hourAndMinute])

                    TextField("Merchant", text: $merchant)
                        .textInputAutocapitalization(.words)

                    if categories.isEmpty {
                        Text("Add categories in Settings")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategoryID) {
                            ForEach(categories) { category in
                                Text(category.name).tag(category.id as UUID?)
                            }
                        }
                    }

                    if accounts.isEmpty {
                        Text("Add cards/accounts in Settings")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Card / Account", selection: $selectedAccountID) {
                            ForEach(accounts) { account in
                                Text(account.name).tag(account.id as UUID?)
                            }
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
                    .disabled(parsedAmount == nil || selectedCategoryID == nil)
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
                .disabled(parsedAmount == nil || selectedCategoryID == nil)
            }
            .onAppear {
                ensureDefaultSelections()
            }
            .onChange(of: categories.count) { _, _ in
                ensureDefaultSelections()
            }
            .onChange(of: accounts.count) { _, _ in
                ensureDefaultSelections()
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
        guard let category = categories.first(where: { $0.id == selectedCategoryID }) else {
            saveError = "Select a category."
            return
        }
        let account = accounts.first(where: { $0.id == selectedAccountID })
        saveError = nil
        let expense = Expense(
            date: expenseDate,
            amount: amount,
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            account: account,
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
            expenseDate = Date()
        } else {
            close()
        }
    }

    private func ensureDefaultSelections() {
        if selectedCategoryID == nil {
            selectedCategoryID = (categories.first { $0.name == "Other" } ?? categories.first)?.id
        }
        if selectedAccountID == nil {
            selectedAccountID = accounts.first?.id
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
