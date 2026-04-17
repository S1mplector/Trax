import SwiftUI
import TraxApplication
import TraxDomain

struct CategoriesView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot

    @State private var newName = ""
    @State private var selectedColor = ColorPreset.presets.first!
    @State private var editingCategoryID: ExpenseCategory.ID?
    @State private var editedName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            addCategory
            categoryList(title: "Active", categories: snapshot.activeCategories)

            if snapshot.archivedCategories.isEmpty == false {
                categoryList(title: "Archived", categories: snapshot.archivedCategories)
            }

            Spacer(minLength: 0)
        }
    }

    private var addCategory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New category")
                .font(.headline)

            TextField("Name", text: $newName)
                .textFieldStyle(.roundedBorder)

            HStack {
                ForEach(ColorPreset.presets) { preset in
                    Button {
                        selectedColor = preset
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.hex))
                            .frame(width: 18, height: 18)
                            .overlay {
                                if selectedColor.id == preset.id {
                                    Circle()
                                        .stroke(.primary, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .help(preset.name)
                }

                Spacer()

                Button("Add") {
                    Task {
                        await store.addCategory(name: newName, colorHex: selectedColor.hex)
                        if store.errorMessage == nil {
                            newName = ""
                        }
                    }
                }
            }
        }
    }

    private func categoryList(title: String, categories: [ExpenseCategory]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(categories) { category in
                CategoryRow(
                    category: category,
                    isEditing: editingCategoryID == category.id,
                    editedName: binding(for: category)
                ) {
                    beginEditing(category)
                } save: {
                    Task {
                        await store.renameCategory(id: category.id, name: editedName)
                        if store.errorMessage == nil {
                            editingCategoryID = nil
                            editedName = ""
                        }
                    }
                } cancel: {
                    editingCategoryID = nil
                    editedName = ""
                }
            }
        }
    }

    private func binding(for category: ExpenseCategory) -> Binding<String> {
        Binding(
            get: {
                editingCategoryID == category.id ? editedName : category.name
            },
            set: { value in
                if editingCategoryID != category.id {
                    editingCategoryID = category.id
                }
                editedName = value
            }
        )
    }

    private func beginEditing(_ category: ExpenseCategory) {
        editingCategoryID = category.id
        editedName = category.name
    }
}

private struct CategoryRow: View {
    @EnvironmentObject private var store: ExpenseStore
    let category: ExpenseCategory
    let isEditing: Bool
    @Binding var editedName: String
    let edit: () -> Void
    let save: () -> Void
    let cancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 10, height: 10)

            if isEditing {
                TextField("Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(category.name)
                    .foregroundStyle(category.isArchived ? .secondary : .primary)
            }

            Spacer()

            if isEditing {
                Button("Save", action: save)
                Button("Cancel", action: cancel)
            } else {
                Button("Rename", action: edit)

                if category.isArchived {
                    Button("Restore") {
                        Task { await store.restoreCategory(id: category.id) }
                    }
                } else {
                    Button("Archive") {
                        Task { await store.archiveCategory(id: category.id) }
                    }
                }

                Button {
                    Task { await store.removeCategory(id: category.id) }
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete category")
            }
        }
        .font(.callout)
    }
}

private struct ColorPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String

    static let presets = [
        ColorPreset(id: "green", name: "Green", hex: "#34C759"),
        ColorPreset(id: "blue", name: "Blue", hex: "#0A84FF"),
        ColorPreset(id: "yellow", name: "Yellow", hex: "#FFD60A"),
        ColorPreset(id: "cyan", name: "Cyan", hex: "#64D2FF"),
        ColorPreset(id: "red", name: "Red", hex: "#FF453A"),
        ColorPreset(id: "gray", name: "Gray", hex: "#8E8E93")
    ]
}
