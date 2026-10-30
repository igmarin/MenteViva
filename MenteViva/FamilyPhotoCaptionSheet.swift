import SwiftUI

/// Names one Memory Lane photo (#139): a few words that help remember who or
/// what it shows. Stays on this device; the sheet says so where it is typed.
struct FamilyPhotoCaptionSheet: View {
    let photo: URL
    /// The line above the field. Set up asks for "a name or a few words"; the first run asks
    /// "Who is this?", the same question Remember Together asks of a photo (#374).
    let promptKey: String
    /// Called after a save or a removal so the photo list can refresh.
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var image: UIImage?
    /// Set when the name couldn't be written, so the sheet stays open and says so.
    @State private var saveProblem = false
    /// A stray tap must not delete a photo and its name for good (#403): Remove asks first.
    @State private var confirmRemove = false

    init(photo: URL, promptKey: String = "family.caption.field", onChange: @escaping () -> Void) {
        self.photo = photo
        self.promptKey = promptKey
        self.onChange = onChange
        _text = State(initialValue: MemoryPhotos.caption(for: photo) ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityHidden(true)
                    }
                    Text(AppLanguage.localized(promptKey))
                        .font(.title3.weight(.semibold))
                    TextField(AppLanguage.localized("family.caption.placeholder"), text: $text)
                        .font(.title3)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 60)
                        .onChange(of: text) { _, new in
                            if new.count > MemoryPhotos.maxCaptionLength {
                                text = String(new.prefix(MemoryPhotos.maxCaptionLength))
                            }
                        }
                    Text(AppLanguage.localized("family.caption.privacy"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                    if saveProblem {
                        Text(AppLanguage.localized("family.caption.save.problem"))
                            .font(.body)
                            .accessibilityAddTraits(.isStaticText)
                    }
                    Button(action: save) {
                        Text(AppLanguage.localized("family.caption.save"))
                            .font(.title3.weight(.semibold))
                    }
                    .buttonStyle(AnswerTileStyle(minHeight: 100))
                    Button(role: .destructive) {
                        confirmRemove = true
                    } label: {
                        Text(AppLanguage.localized("family.photos.remove"))
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 100)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle(AppLanguage.localized("family.caption.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppLanguage.localized("settings.done")) { dismiss() }
                        .font(.title3)
                        .bigTapTarget()
                }
            }
            .task { image = await MemoryPhotos.image(at: photo) }
            // An alert, not a confirmationDialog: on iPhone inside a sheet that one floats as a popover and
            // drops its Cancel button, so "Keep it" would not show.
            .alert(
                AppLanguage.localized("family.photos.remove.confirm"),
                isPresented: $confirmRemove
            ) {
                Button(AppLanguage.localized("family.photos.remove"), role: .destructive, action: remove)
                Button(AppLanguage.localized("family.photos.remove.cancel"), role: .cancel) {}
            } message: {
                // The saved name, so VoiceOver says which photo is going; a photo without one has none.
                if let name = MemoryPhotos.caption(for: photo) { Text(name) }
            }
        }
    }

    private func save() {
        do {
            try MemoryPhotos.setCaption(text, for: photo)
        } catch {
            saveProblem = true
            AccessibilityNotification.Announcement(AppLanguage.localized("family.caption.save.problem")).post()
            return
        }
        onChange()
        dismiss()
    }

    private func remove() {
        MemoryPhotos.remove(photo)
        onChange()
        dismiss()
    }
}
