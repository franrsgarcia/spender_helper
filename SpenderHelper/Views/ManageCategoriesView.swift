import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var newCategoryName = ""
    @State private var categoryToDelete: Category?
    @State private var showDeleteAlert = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New category", text: $newCategoryName)
                    Button("Add") {
                        addCategory()
                    }
                    .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section("Categories") {
                ForEach(categories) { category in
                    Text(category.name)
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
        .navigationTitle("Categories")
        .alert("Delete Category?", isPresented: $showDeleteAlert, presenting: categoryToDelete) { category in
            Button("Delete", role: .destructive) {
                deleteCategory(category)
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: { category in
            let count = category.expenses?.count ?? 0
            if count > 0 {
                Text("\"\(category.name)\" is used by \(count) expense(s). They will be moved to Other.")
            } else {
                Text("Delete \"\(category.name)\"?")
            }
        }
    }

    private func addCategory() {
        errorMessage = nil
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if categories.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            errorMessage = "A category with that name already exists."
            return
        }
        let nextOrder = (categories.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(Category(name: name, sortOrder: nextOrder))
        newCategoryName = ""
        try? modelContext.save()
    }

    private func requestDelete(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        categoryToDelete = categories[index]
        showDeleteAlert = true
    }

    private func deleteCategory(_ category: Category) {
        errorMessage = nil
        if categories.count <= 1 {
            errorMessage = "Keep at least one category."
            categoryToDelete = nil
            return
        }
        let fallback = categories.first { $0.id != category.id && $0.name == "Other" }
            ?? categories.first { $0.id != category.id }
        if let expenses = category.expenses {
            for expense in expenses {
                expense.category = fallback
                expense.categoryRaw = fallback?.name ?? ""
            }
        }
        modelContext.delete(category)
        try? modelContext.save()
        categoryToDelete = nil
    }
}
