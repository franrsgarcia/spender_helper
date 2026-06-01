import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportBankStatementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @State private var showFileImporter = false
    @State private var showDocumentPicker = false
    @State private var selectedAccountID: UUID?
    @State private var isImporting = false
    @State private var resultMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Text("Import a Caixa \"Consulta de movimentos\" CSV export. Only debit (expense) rows are imported. Manual expenses are not changed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !accounts.isEmpty {
                Section("Link to account") {
                    Picker("Account", selection: $selectedAccountID) {
                        Text("Auto-detect from file").tag(nil as UUID?)
                        ForEach(accounts) { account in
                            Text(account.name).tag(account.id as UUID?)
                        }
                    }
                }
            }

            Section {
                Button {
                    showDocumentPicker = true
                } label: {
                    Label("Browse Files", systemImage: "folder")
                }
                .disabled(isImporting)

                Button {
                    showFileImporter = true
                } label: {
                    Label("Choose CSV File", systemImage: "doc.badge.arrow.up")
                }
                .disabled(isImporting)

                if isImporting {
                    ProgressView("Importing…")
                }
            }

            if let resultMessage {
                Section("Last import") {
                    Text(resultMessage)
                        .font(.footnote)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Import Bank CSV")
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(
                onPick: { url in
                    showDocumentPicker = false
                    importFile(at: url)
                },
                onCancel: { showDocumentPicker = false }
            )
        }
        .onAppear {
            if selectedAccountID == nil {
                selectedAccountID = accounts.first?.id
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        resultMessage = nil

        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            importFile(at: url)
        }
    }

    private func importFile(at url: URL) {
        isImporting = true
        defer { isImporting = false }

        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .windowsCP1252) else {
                throw BankStatementImportError.unreadableFile
            }

            let target = accounts.first { $0.id == selectedAccountID }
            let result = try BankStatementImportService.importStatement(
                csvText: text,
                into: modelContext,
                targetAccount: target
            )

            resultMessage = """
            Account: \(result.accountName)
            Added \(result.added) expenses, updated \(result.updated), removed \(result.removed) stale bank rows.
            Skipped \(result.skippedIncome) income/credit rows.
            """
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
