import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink {
                ManageCategoriesView()
            } label: {
                Label("Categories", systemImage: "tag")
            }
            NavigationLink {
                ManageAccountsView()
            } label: {
                Label("Cards & Accounts", systemImage: "creditcard")
            }
            NavigationLink {
                ImportBankStatementView()
            } label: {
                Label("Import Bank CSV", systemImage: "doc.badge.arrow.up")
            }
        }
        .navigationTitle("Settings")
    }
}
