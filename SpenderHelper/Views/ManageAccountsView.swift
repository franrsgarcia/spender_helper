import SwiftUI
import SwiftData

struct ManageAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @State private var newAccountName = ""
    @State private var accountToDelete: Account?
    @State private var showDeleteAlert = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("e.g. Visa ••1234", text: $newAccountName)
                    Button("Add") {
                        addAccount()
                    }
                    .disabled(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section("Cards & Accounts") {
                ForEach(accounts) { account in
                    Text(account.name)
                }
                .onDelete(perform: requestDelete)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Cards & Accounts")
        .alert("Delete Account?", isPresented: $showDeleteAlert, presenting: accountToDelete) { account in
            Button("Delete", role: .destructive) {
                deleteAccount(account)
            }
            Button("Cancel", role: .cancel) {
                accountToDelete = nil
            }
        } message: { account in
            let count = account.expenses?.count ?? 0
            if count > 0 {
                Text("\"\(account.name)\" is used by \(count) expense(s). They will have no account assigned.")
            } else {
                Text("Delete \"\(account.name)\"?")
            }
        }
    }

    private func addAccount() {
        errorMessage = nil
        let name = newAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if accounts.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            errorMessage = "An account with that name already exists."
            return
        }
        let nextOrder = (accounts.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(Account(name: name, sortOrder: nextOrder))
        newAccountName = ""
        try? modelContext.save()
    }

    private func requestDelete(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        accountToDelete = accounts[index]
        showDeleteAlert = true
    }

    private func deleteAccount(_ account: Account) {
        errorMessage = nil
        if accounts.count <= 1 {
            errorMessage = "Keep at least one account."
            accountToDelete = nil
            return
        }
        if let expenses = account.expenses {
            for expense in expenses {
                expense.account = nil
            }
        }
        modelContext.delete(account)
        try? modelContext.save()
        accountToDelete = nil
    }
}
