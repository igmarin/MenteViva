import SwiftUI

/// Names one Memory Lane photo (#139): a few words that help remember who or
/// what it shows. Stays on this device; the sheet says so where it is typed.
struct FamilyPhotoCaptionSheet: View {
    let photo: URL
    /// Called after a save or a removal so the photo list can refresh.
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var image: UIImage?
    /// Set when the name couldn't be written, so the sheet stays open and says so.
    @State private var saveProblem = false

    init(photo: URL, onChange: @escaping () -> Void) {
        self.photo = photo
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
                    Text(AppLanguage.localized("family.caption.field"))
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
                    Button(role: .destructive, action: remove) {
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
            .task { image = UIImage(contentsOfFile: photo.path) }
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
