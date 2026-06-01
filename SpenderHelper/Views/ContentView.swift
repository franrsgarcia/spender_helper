import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var showQuickLog = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var expenseToEdit: Expense?

    var body: some View {
        NavigationStack {
            Group {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses Yet",
                        systemImage: "creditcard",
                        description: Text("Log a purchase after using Wallet, or tap + to add one.")
                    )
                } else {
                    List {
                        ForEach(expenses) { expense in
                            ExpenseRowView(expense: expense)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    expenseToEdit = expense
                                }
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                }
            }
            .navigationTitle("Spender Helper")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(expenses.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showQuickLog = true
                    } label: {
                        Label("Log Expense", systemImage: "plus")
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

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(expenses[index])
        }
    }

    private func exportCSV() {
        do {
            let url = try CsvExportService.export(expenses: expenses)
            exportURL = url
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}
