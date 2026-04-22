import SwiftUI
import TraxApplication
import TraxDomain

struct CategoriesView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot

    @State private var newName = ""
    @State private var selectedColorHex = ColorPreset.recommended(isEssential: false).hex
    @State private var newCategoryIsEssential = false
    @State private var editingCategoryID: ExpenseCategory.ID?
    @State private var colorEditingCategoryID: ExpenseCategory.ID?
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
    }

    private var newCategorySection: some View {
        PanelSection("New category", detail: "Use categories for decisions you want to notice.") {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(submitCategory)

                CategoryColorPicker(selectionHex: $selectedColorHex)

                HStack {
                    Toggle("Essential", isOn: $newCategoryIsEssential)
                        .toggleStyle(.checkbox)
                        .onChange(of: newCategoryIsEssential) { _, isEssential in
                            selectedColorHex = ColorPreset.recommended(isEssential: isEssential).hex
                        }

                    PrimaryInlineButton(
                        title: "Add",
                        minWidth: 48,
                        isEnabled: canAddCategory,
                        action: submitCategory
                    )
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
                            isColorEditing: colorEditingCategoryID == category.id,
                            isPendingRemoval: categoryPendingRemoval?.id == category.id,
                            editedName: binding(for: category),
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
                            toggleColorEditor: {
                                categoryPendingRemoval = nil
                                if colorEditingCategoryID == category.id {
                                    colorEditingCategoryID = nil
                                } else {
                                    editingCategoryID = nil
                                    editedName = ""
                                    colorEditingCategoryID = category.id
                                }
                            },
                            closeColorEditor: {
                                colorEditingCategoryID = nil
                            },
                            updateColor: { colorHex in
                                Task { await store.updateCategoryColor(id: category.id, colorHex: colorHex) }
                            },
                            toggleEssential: {
                                Task {
                                    await store.updateCategoryEssential(
                                        id: category.id,
                                        isEssential: category.isEssential == false
                                    )
                                }
                            },
                            archiveOrRestore: {
                                Task {
                                    categoryPendingRemoval = nil
                                    if category.isArchived {
                                        await store.restoreCategory(id: category.id)
                                    } else {
                                        await store.archiveCategory(id: category.id)
                                    }
                                }
                            },
                            requestRemove: {
                                editingCategoryID = nil
                                colorEditingCategoryID = nil
                                editedName = ""
                                categoryPendingRemoval = category
                            },
                            confirmRemove: {
                                Task {
                                    await store.removeCategory(id: category.id)
                                    if store.errorMessage == nil {
                                        categoryPendingRemoval = nil
                                    }
                                }
                            },
                            cancelRemove: {
                                categoryPendingRemoval = nil
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
        categoryPendingRemoval = nil
        colorEditingCategoryID = nil
        editingCategoryID = category.id
        editedName = category.name
    }

    private var canAddCategory: Bool {
        newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func submitCategory() {
        Task {
            await store.addCategory(name: newName, colorHex: selectedColorHex, isEssential: newCategoryIsEssential)
            if store.errorMessage == nil {
                newName = ""
                newCategoryIsEssential = false
                selectedColorHex = ColorPreset.recommended(isEssential: false).hex
            }
        }
    }
}

private struct CategoryRow: View {
    let category: ExpenseCategory
    let isEditing: Bool
    let isColorEditing: Bool
    let isPendingRemoval: Bool
    @Binding var editedName: String
    let edit: () -> Void
    let save: () -> Void
    let cancel: () -> Void
    let toggleColorEditor: () -> Void
    let closeColorEditor: () -> Void
    let updateColor: (String) -> Void
    let toggleEssential: () -> Void
    let archiveOrRestore: () -> Void
    let requestRemove: () -> Void
    let confirmRemove: () -> Void
    let cancelRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row

            if isPendingRemoval {
                removeConfirmation
            } else if isEditing {
                renameEditor
            } else if isColorEditing {
                colorEditor
            }
        }
        .font(.callout)
        .padding(.vertical, 6)
    }

    private var row: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 10, height: 10)

            if isEditing {
                TextField("Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .foregroundStyle(category.isArchived ? .secondary : .primary)
                        .lineLimit(1)

                    Text(SpendKindColors.label(isEssential: category.isEssential))
                        .font(.caption)
                        .foregroundStyle(SpendKindColors.color(isEssential: category.isEssential))
                }
            }

            Spacer(minLength: 12)

            if isPendingRemoval == false {
                CategoryIconButton(systemName: "pencil", help: "Rename", action: edit)
                CategoryIconButton(
                    systemName: isColorEditing ? "paintpalette.fill" : "paintpalette",
                    help: isColorEditing ? "Hide color controls" : "Change color",
                    action: toggleColorEditor
                )
                CategoryIconButton(
                    systemName: category.isArchived ? "arrow.uturn.backward" : "archivebox",
                    help: category.isArchived ? "Restore" : "Archive",
                    action: archiveOrRestore
                )
                CategoryIconButton(
                    systemName: category.isEssential ? "exclamationmark.triangle.fill" : "tag.fill",
                    help: category.isEssential ? "Mark non-essential" : "Mark essential",
                    action: toggleEssential
                )
                CategoryIconButton(systemName: "trash", help: "Remove", role: .destructive, action: requestRemove)
            }
        }
    }

    private var renameEditor: some View {
        HStack {
            Spacer()
            Button("Save", action: save)
                .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", action: cancel)
        }
        .padding(.leading, 20)
    }

    private var colorEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            CategoryColorPicker(
                selectionHex: Binding(
                    get: { category.colorHex },
                    set: { updateColor($0) }
                )
            )

            HStack {
                Spacer()
                Button("Done", action: closeColorEditor)
            }
        }
        .padding(.leading, 20)
    }

    private var removeConfirmation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remove \(category.name)?")
                .font(.caption.weight(.medium))

            Text("Unused categories are deleted. Categories with expenses are archived.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel", action: cancelRemove)
                    .controlSize(.small)
                DestructiveInlineButton(title: "Remove", action: confirmRemove)
            }
        }
        .padding(8)
        .background(Color.red.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.leading, 20)
    }
}

private struct DestructiveInlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 62)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .background(Color.red.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .help(title)
    }
}

private struct CategoryIconButton: View {
    let systemName: String
    let help: String
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}

private struct CategoryColorPicker: View {
    @Binding var selectionHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ColorPresetButtons(selectedHex: selectionHex) { preset in
                selectionHex = preset.hex
            }

            HStack(spacing: 10) {
                ColorPicker(
                    "Custom",
                    selection: Binding(
                        get: { Color(hex: selectionHex) },
                        set: { color in
                            if let hexString = color.hexString {
                                selectionHex = hexString
                            }
                        }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()

                Text("Custom")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(selectionHex)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }
}

private struct ColorPresetButtons: View {
    let selectedHex: String
    let select: (ColorPreset) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ColorPreset.presets) { preset in
                Button {
                    select(preset)
                } label: {
                    Circle()
                        .fill(Color(hex: preset.hex))
                        .frame(width: 18, height: 18)
                        .overlay {
                            if preset.hex.caseInsensitiveCompare(selectedHex) == .orderedSame {
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
        ColorPreset(id: "orange", name: "Orange", hex: "#FF9F0A"),
        ColorPreset(id: "green", name: "Green", hex: "#34C759"),
        ColorPreset(id: "blue", name: "Blue", hex: "#0A84FF"),
        ColorPreset(id: "yellow", name: "Yellow", hex: "#FFD60A"),
        ColorPreset(id: "cyan", name: "Cyan", hex: "#64D2FF"),
        ColorPreset(id: "red", name: "Red", hex: "#FF453A"),
        ColorPreset(id: "gray", name: "Gray", hex: "#8E8E93")
    ]

    static func recommended(isEssential: Bool) -> ColorPreset {
        if isEssential {
            return presets.first { $0.id == "orange" } ?? presets[0]
        }

        return presets.first { $0.id == "red" } ?? presets[0]
    }
}
