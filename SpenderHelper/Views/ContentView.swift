import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    @State private var filters = ExpenseFilters()
    @State private var showFilters = false
    @State private var showSettings = false
    @State private var showQuickLog = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var expenseToEdit: Expense?

    private var filteredExpenses: [Expense] {
        filters.apply(to: allExpenses)
    }

    var body: some View {
        NavigationStack {
            Group {
                if allExpenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses Yet",
                        systemImage: "creditcard",
                        description: Text("Log a purchase after using Wallet, or tap + to add one.")
                    )
                } else if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "No Matching Expenses",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Try changing or clearing your filters.")
                    )
                } else {
                    List {
                        BalanceSheetSummaryView()
                        if filters.hasActiveFilters {
                            Section {
                                Text("Showing \(filteredExpenses.count) of \(allExpenses.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Section {
                            ForEach(filteredExpenses) { expense in
                                ExpenseRowView(expense: expense)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        expenseToEdit = expense
                                    }
                            }
                            .onDelete(perform: deleteFilteredExpenses)
                        }
                    }
                }
            }
            .navigationTitle("Spender Helper")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showFilters = true
                        } label: {
                            Label("Filters", systemImage: filters.hasActiveFilters
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle")
                        }
                        Button {
                            exportCSV()
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .disabled(filteredExpenses.isEmpty)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        Button {
                            showQuickLog = true
                        } label: {
                            Label("Log Expense", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                ExpenseFiltersView(filters: $filters)
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showQuickLog) {
                QuickLogView(onDismiss: { showQuickLog = false })
            }
            .sheet(isPresented: Binding(
                get: { expenseToEdit != nil },
                set: { if !$0 { expenseToEdit = nil } }
            )) {
                if let expenseToEdit {
                    ExpenseEditView(expense: expenseToEdit)
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                exportURL = nil
            }) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private func deleteFilteredExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredExpenses[index])
        }
    }

    private func exportCSV() {
        do {
            let url = try CsvExportService.export(expenses: filteredExpenses)
            exportURL = url
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}

extension Expense: @retroactive Identifiable {}
