import AppIntents
import SwiftData

struct ExportExpensesIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Expenses"
    static var description = IntentDescription("Export all expenses as a CSV file for Excel or Google Sheets.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let context = ModelContext(DataController.sharedModelContainer)
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let expenses = try context.fetch(descriptor)
        guard !expenses.isEmpty else {
            throw ExportExpensesError.noExpenses
        }
        let url = try CsvExportService.export(expenses: expenses)
        let file = IntentFile(fileURL: url, filename: url.lastPathComponent)
        return .result(value: file)
    }
}

enum ExportExpensesError: Error, CustomLocalizedStringResourceConvertible {
    case noExpenses

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noExpenses:
            return "No expenses to export. Log at least one expense first."
        }
    }
}
