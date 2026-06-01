import Foundation

enum CsvExportService {
    private static let header = "date,time,amount,currency,merchant,category,notes"

    static func export(expenses: [Expense]) throws -> URL {
        let sorted = expenses.sorted { $0.date > $1.date }
        var lines = [header]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm:ss"

        for expense in sorted {
            let date = dateFormatter.string(from: expense.date)
            let time = timeFormatter.string(from: expense.date)
            let amount = formatAmount(expense.amount)
            let row = [
                date,
                time,
                amount,
                expense.currency,
                expense.merchant,
                expense.categoryRaw,
                expense.notes,
            ]
            lines.append(row.map(escapeField).joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n") + "\n"
        let fileName = "expenses-\(exportTimestamp()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func formatAmount(_ amount: Decimal) -> String {
        let number = amount as NSDecimalNumber
        return String(format: "%.2f", number.doubleValue)
    }

    private static func escapeField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    private static func exportTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
