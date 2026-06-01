import Foundation
import SwiftData

struct BankStatementMetadata: Equatable {
    var accountLabel: String
    var accountNumber: String
    var accountingBalance: Decimal?
    var availableBalance: Decimal?
    var currency: String
    var periodStart: Date?
    var periodEnd: Date?
}

struct BankMovementRow: Equatable {
    var movementDate: Date
    var valueDate: Date
    var description: String
    var amount: Decimal
    var balanceAfter: Decimal?
    var importKey: String
}

struct BankStatementParseResult {
    var metadata: BankStatementMetadata
    var movements: [BankMovementRow]
}

struct BankImportResult {
    var added: Int
    var updated: Int
    var removed: Int
    var skippedIncome: Int
    var accountName: String
}

enum BankStatementImportError: LocalizedError {
    case unreadableFile
    case invalidFormat
    case noExpenseCategory

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "Could not read the selected file."
        case .invalidFormat:
            return "This file does not look like a Caixa bank movements export."
        case .noExpenseCategory:
            return "Add at least one category before importing."
        }
    }
}

enum BankStatementImportService {
    private static let movementHeader = "Data mov.;Data-valor;Descrição;Montante;Saldo contabilístico após movimento"

    static func parse(csvText: String) throws -> BankStatementParseResult {
        let lines = csvText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let headerIndex = lines.firstIndex(where: { normalizeHeader($0) == normalizeHeader(movementHeader) }) else {
            throw BankStatementImportError.invalidFormat
        }

        var metadata = BankStatementMetadata(
            accountLabel: "",
            accountNumber: "",
            accountingBalance: nil,
            availableBalance: nil,
            currency: "EUR",
            periodStart: nil,
            periodEnd: nil
        )

        for line in lines.prefix(headerIndex) {
            parseMetadataLine(line, into: &metadata)
        }

        var movements: [BankMovementRow] = []
        for line in lines.dropFirst(headerIndex + 1) {
            if let row = parseMovementLine(line) {
                movements.append(row)
            }
        }

        guard !movements.isEmpty else {
            throw BankStatementImportError.invalidFormat
        }

        return BankStatementParseResult(metadata: metadata, movements: movements)
    }

    @MainActor
    static func importStatement(
        csvText: String,
        into context: ModelContext,
        targetAccount: Account? = nil
    ) throws -> BankImportResult {
        let parsed = try parse(csvText: csvText)
        let categories = try context.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)]))
        guard let defaultCategory = categories.first(where: { $0.name == "Other" }) ?? categories.first else {
            throw BankStatementImportError.noExpenseCategory
        }

        let account = try resolveAccount(metadata: parsed.metadata, targetAccount: targetAccount, context: context)
        applyMetadata(parsed.metadata, to: account)

        let expenseRows = parsed.movements.filter { $0.amount < 0 }
        let skippedIncome = parsed.movements.count - expenseRows.count
        let newKeys = Set(expenseRows.map(\.importKey))

        let linkedExpenses = try context.fetch(FetchDescriptor<Expense>())
            .filter { $0.account?.id == account.id && $0.importSource == "bank" }

        var removed = 0
        for expense in linkedExpenses where !newKeys.contains(expense.importKey) {
            context.delete(expense)
            removed += 1
        }

        var added = 0
        var updated = 0
        let existingByKey = Dictionary(
            uniqueKeysWithValues: linkedExpenses.map { ($0.importKey, $0) }
        )

        for row in expenseRows {
            let amount = abs(row.amount)
            if var existing = existingByKey[row.importKey] {
                existing.date = row.movementDate
                existing.merchant = row.description
                existing.amount = amount
                existing.currency = parsed.metadata.currency
                existing.notes = valueDateNote(row.valueDate)
                updated += 1
            } else {
                let expense = Expense(
                    date: row.movementDate,
                    amount: amount,
                    currency: parsed.metadata.currency,
                    merchant: row.description,
                    category: defaultCategory,
                    account: account,
                    notes: valueDateNote(row.valueDate),
                    importSource: "bank",
                    importKey: row.importKey
                )
                context.insert(expense)
                added += 1
            }
        }

        account.lastImportedAt = Date()
        try context.save()

        return BankImportResult(
            added: added,
            updated: updated,
            removed: removed,
            skippedIncome: skippedIncome,
            accountName: account.name
        )
    }

    // MARK: - Parsing helpers

    private static func normalizeHeader(_ line: String) -> String {
        line.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private static func parseMetadataLine(_ line: String, into metadata: inout BankStatementMetadata) {
        let parts = line.split(separator: ";", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return }
        let key = parts[0]
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        let value = parts[1]

        switch key {
        case "conta":
            metadata.accountLabel = value
            metadata.accountNumber = extractAccountNumber(from: value)
            if value.contains("EUR") { metadata.currency = "EUR" }
        case "saldo contabilístico", "saldo contabilistico":
            metadata.accountingBalance = parsePortugueseAmount(value)
        case "saldo disponível", "saldo disponivel":
            metadata.availableBalance = parsePortugueseAmount(value)
        case "intervalo de":
            let range = parseDateRange(value)
            metadata.periodStart = range?.start
            metadata.periodEnd = range?.end
        default:
            break
        }
    }

    private static func parseMovementLine(_ line: String) -> BankMovementRow? {
        let parts = splitSemicolonRow(line)
        guard parts.count >= 4 else { return nil }
        guard let movementDate = parsePortugueseDate(parts[0]),
              let valueDate = parsePortugueseDate(parts[1]),
              let amount = parsePortugueseAmount(parts[3]) else {
            return nil
        }
        let description = parts[2]
        let balanceAfter = parts.count > 4 ? parsePortugueseAmount(parts[4]) : nil
        let key = "\(parts[0])|\(description)|\(parts[3])"
        return BankMovementRow(
            movementDate: movementDate,
            valueDate: valueDate,
            description: description,
            amount: amount,
            balanceAfter: balanceAfter,
            importKey: key
        )
    }

    private static func splitSemicolonRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        for character in line {
            if character == "\"" {
                inQuotes.toggle()
                continue
            }
            if character == ";" && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }

    static func parsePortugueseAmount(_ raw: String) -> Decimal? {
        var text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        let negative = text.hasPrefix("-")
        if negative { text.removeFirst() }

        if let eurRange = text.range(of: " EUR", options: [.caseInsensitive]) {
            text = String(text[..<eurRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        }

        text = text.replacingOccurrences(of: ".", with: "")
        text = text.replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: text) else { return nil }
        return negative ? -value : value
    }

    private static func parsePortugueseDate(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "dd-MM-yyyy"
        guard let day = formatter.date(from: raw.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }

    private static func parseDateRange(_ raw: String) -> (start: Date, end: Date)? {
        let parts = raw.components(separatedBy: " a ")
        guard parts.count == 2,
              let start = parsePortugueseDate(parts[0]),
              let end = parsePortugueseDate(parts[1]) else {
            return nil
        }
        return (start, end)
    }

    private static func extractAccountNumber(from label: String) -> String {
        let digits = label.filter(\.isNumber)
        return digits.isEmpty ? label : digits
    }

    private static func valueDateNote(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "dd-MM-yyyy"
        return "Data-valor: \(formatter.string(from: date))"
    }

    @MainActor
    private static func resolveAccount(
        metadata: BankStatementMetadata,
        targetAccount: Account?,
        context: ModelContext
    ) throws -> Account {
        if let targetAccount {
            if !metadata.accountNumber.isEmpty {
                targetAccount.bankAccountNumber = metadata.accountNumber
            }
            if !metadata.accountLabel.isEmpty, targetAccount.name == "Default" || targetAccount.name.isEmpty {
                targetAccount.name = metadata.accountLabel
            }
            return targetAccount
        }

        let accounts = try context.fetch(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)]))
        if !metadata.accountNumber.isEmpty,
           let match = accounts.first(where: { $0.bankAccountNumber == metadata.accountNumber }) {
            return match
        }

        if let first = accounts.first, accounts.count == 1 {
            if !metadata.accountNumber.isEmpty {
                first.bankAccountNumber = metadata.accountNumber
            }
            if !metadata.accountLabel.isEmpty {
                first.name = metadata.accountLabel
            }
            return first
        }

        let name = metadata.accountLabel.isEmpty ? "Bank Account" : metadata.accountLabel
        let nextOrder = (accounts.map(\.sortOrder).max() ?? -1) + 1
        let account = Account(
            name: name,
            sortOrder: nextOrder,
            bankAccountNumber: metadata.accountNumber
        )
        context.insert(account)
        return account
    }

    private static func applyMetadata(_ metadata: BankStatementMetadata, to account: Account) {
        if !metadata.accountNumber.isEmpty {
            account.bankAccountNumber = metadata.accountNumber
        }
        if !metadata.accountLabel.isEmpty {
            account.name = metadata.accountLabel
        }
        account.accountingBalance = metadata.accountingBalance
        account.availableBalance = metadata.availableBalance
        account.balanceCurrency = metadata.currency
        account.statementPeriodStart = metadata.periodStart
        account.statementPeriodEnd = metadata.periodEnd
    }
}
