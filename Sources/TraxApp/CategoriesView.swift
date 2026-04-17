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
    @State private var categoryPendingRemoval: ExpenseCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            newCategorySection
            categoryList(title: "Active", categories: snapshot.activeCategories)

            if snapshot.archivedCategories.isEmpty == false {
                categoryList(title: "Archived", categories: snapshot.archivedCategories)
            }

        }
        .confirmationDialog(
            "Remove category?",
            isPresented: Binding(
                get: { categoryPendingRemoval != nil },
                set: { if $0 == false { categoryPendingRemoval = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let category = categoryPendingRemoval {
                Button("Remove category", role: .destructive) {
                    Task { await store.removeCategory(id: category.id) }
                }
            }
        } message: {
            if let category = categoryPendingRemoval {
                Text("Remove \(category.name)? Unused categories are deleted. Categories with expenses are archived to keep history intact.")
            }
        }
    }

    private var newCategorySection: some View {
        PanelSection("New category", detail: "Use categories for decisions you want to notice.") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submitCategory)

                HStack {
                    ColorPresetPicker(selection: $selectedColor)

                    Spacer()

                    Button("Add", action: submitCategory)
                        .buttonStyle(.borderedProminent)
                        .disabled(canAddCategory == false)
                }
            }
        }
    }

    private func categoryList(title: String, categories: [ExpenseCategory]) -> some View {
        PanelSection(title) {
            if categories.isEmpty {
                EmptyStateView(
                    title: "No \(title.lowercased()) categories.",
                    message: "Categories you add will appear here."
                )
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(categories) { category in
                        CategoryRow(
                            category: category,
                            isEditing: editingCategoryID == category.id,
                            editedName: binding(for: category),
                            selectedPreset: ColorPreset.matching(category.colorHex),
                            edit: {
                                beginEditing(category)
                            },
                            save: {
                                Task {
                                    await store.renameCategory(id: category.id, name: editedName)
                                    if store.errorMessage == nil {
                                        editingCategoryID = nil
                                        editedName = ""
                                    }
                                }
                            },
                            cancel: {
                                editingCategoryID = nil
                                editedName = ""
                            },
                            updateColor: { preset in
                                Task { await store.updateCategoryColor(id: category.id, colorHex: preset.hex) }
                            },
                            archiveOrRestore: {
                                Task {
                                    if category.isArchived {
                                        await store.restoreCategory(id: category.id)
                                    } else {
                                        await store.archiveCategory(id: category.id)
                                    }
                                }
                            },
                            requestRemove: {
                                categoryPendingRemoval = category
                            }
                        )
                    }
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

    private var canAddCategory: Bool {
        newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func submitCategory() {
        Task {
            await store.addCategory(name: newName, colorHex: selectedColor.hex)
            if store.errorMessage == nil {
                newName = ""
            }
        }
    }
}

private struct CategoryRow: View {
    let category: ExpenseCategory
    let isEditing: Bool
    @Binding var editedName: String
    let selectedPreset: ColorPreset
    let edit: () -> Void
    let save: () -> Void
    let cancel: () -> Void
    let updateColor: (ColorPreset) -> Void
    let archiveOrRestore: () -> Void
    let requestRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 10, height: 10)

            if isEditing {
                TextField("Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)
            } else {
                Text(category.name)
                    .foregroundStyle(category.isArchived ? .secondary : .primary)
            }

            Spacer()

            if isEditing {
                Button("Save", action: save)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", action: cancel)
            } else {
                Menu {
                    ForEach(ColorPreset.presets) { preset in
                        Button {
                            updateColor(preset)
                        } label: {
                            Label(preset.name, systemImage: selectedPreset.id == preset.id ? "checkmark.circle.fill" : "circle.fill")
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette")
                }
                .menuStyle(.borderlessButton)
                .help("Change color")

                Menu {
                    Button("Rename", action: edit)
                    Button(category.isArchived ? "Restore" : "Archive", action: archiveOrRestore)
                    Divider()
                    Button("Remove", role: .destructive, action: requestRemove)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .help("Category actions")
            }
        }
        .font(.callout)
        .padding(.vertical, 3)
    }
}

private struct ColorPresetPicker: View {
    @Binding var selection: ColorPreset

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ColorPreset.presets) { preset in
                Button {
                    selection = preset
                } label: {
                    Circle()
                        .fill(Color(hex: preset.hex))
                        .frame(width: 18, height: 18)
                        .overlay {
                            if selection.id == preset.id {
                                Circle()
                                    .stroke(.primary, lineWidth: 2)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(preset.name)
            }
        }
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

    static func matching(_ hex: String) -> ColorPreset {
        presets.first { $0.hex.caseInsensitiveCompare(hex) == .orderedSame } ?? presets[5]
    }
}
