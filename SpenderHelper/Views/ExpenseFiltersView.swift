import SwiftUI
import SwiftData

struct ExpenseFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @Binding var filters: ExpenseFilters

    var body: some View {
        NavigationStack {
            Form {
                Section("Time Period") {
                    Picker("Period", selection: $filters.period) {
                        ForEach(TimePeriodFilter.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    if filters.period == .custom {
                        DatePicker("From", selection: $filters.customStart, displayedComponents: .date)
                        DatePicker("To", selection: $filters.customEnd, displayedComponents: .date)
                    }
                }

                Section {
                    if categories.isEmpty {
                        Text("No categories yet. Add them in Settings.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories) { category in
                            Toggle(category.name, isOn: categoryBinding(category))
                        }
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    Text("Leave all off to include every category.")
                }

                Section {
                    if accounts.isEmpty {
                        Text("No accounts yet. Add them in Settings.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(accounts) { account in
                            Toggle(account.name, isOn: accountBinding(account))
                        }
                    }
                } header: {
                    Text("Cards & Accounts")
                } footer: {
                    Text("Leave all off to include every account.")
                }

                if filters.hasActiveFilters {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            filters = ExpenseFilters()
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func categoryBinding(_ category: Category) -> Binding<Bool> {
        Binding(
            get: { filters.selectedCategoryIDs.contains(category.id) },
            set: { isOn in
                if isOn {
                    filters.selectedCategoryIDs.insert(category.id)
                } else {
                    filters.selectedCategoryIDs.remove(category.id)
                }
            }
        )
    }

    private func accountBinding(_ account: Account) -> Binding<Bool> {
        Binding(
            get: { filters.selectedAccountIDs.contains(account.id) },
            set: { isOn in
                if isOn {
                    filters.selectedAccountIDs.insert(account.id)
                } else {
                    filters.selectedAccountIDs.remove(account.id)
                }
            }
        )
    }
}

extension Category: @retroactive Identifiable {}
extension Account: @retroactive Identifiable {}
