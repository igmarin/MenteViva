import PhotosUI
import SwiftUI

/// First run, for someone who has never heard of this app and has nobody to ask (#212).
///
/// Step 1 is the welcome screen, kept as it was: title, three short lines, the language
/// choice, Start. Steps 2-5 are the four questions from `OnboardingSteps`, one per screen:
/// big answer tiles, a visible Skip, Back, and a "2 of 5" dot row. Answers save as they are
/// given, so a flow left half-way keeps what was answered, and every one of them can be
/// changed later in Settings -> My plan. No age, no health question, no text field.
///
/// After the questions come up to two offers outside the count, in the order
/// `OnboardingSteps.afterQuestions` gives: family photos while the album is empty (#374), then
/// the warm-up (#213). Each can be passed with one tap.
///
/// Claim ceiling is deliberate (research §1, App Store 1.4.1): "keep your mind
/// active", never treatment, prevention or diagnosis.
struct OnboardingView: View {
    /// UserDefaults key: true once the first-run screens have been passed.
    static let seenKey = "hasSeenOnboarding"

    @AppStorage(OnboardingView.seenKey) private var hasSeenOnboarding = false
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.system.rawValue
    /// Bigger text needs the whole width for one answer, so the grid becomes a single column.
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The step on screen: 1 is the welcome screen, 2-5 are the questions in order.
    @State private var step = 1
    /// The answers so far. Saved after every tap, so leaving mid-way loses nothing.
    @State private var profile = ProfileStore.load()
    /// The offers after the last question, fixed when the player leaves it, so adding photos on
    /// the photo screen doesn't renumber the screens behind it.
    @State private var offers: [OnboardingOffer] = []
    /// What the photo picker handed over; cleared once the photos are in the album.
    @State private var picked: [PhotosPickerItem] = []
    /// What the last pick did when no photo could be used, in plain words (#120).
    @State private var photoNote: String?
    /// New photos still waiting for their name, in the order they were picked.
    @State private var toName: [URL] = []
    /// The photo being named now.
    @State private var naming: CaptionTarget?

    /// This step's question, or nil on the welcome screen and the offers after the questions.
    private var question: OnboardingQuestion? {
        (2...OnboardingSteps.stepCount).contains(step) ? OnboardingSteps.questions[step - 2] : nil
    }

    /// This step's offer, or nil while the questions are still being asked.
    private var offer: OnboardingOffer? {
        let index = step - OnboardingSteps.stepCount - 1
        return offers.indices.contains(index) ? offers[index] : nil
    }

    var body: some View {
        VStack(spacing: 24) {
            if let offer {
                switch offer {
                case .photos: photosOffer
                case .warmUp: warmUpOffer
                }
            } else if let question {
                questionStep(question)
            } else {
                welcome
            }
        }
        // At the largest text sizes the screens scroll, so the answers and Skip stay reachable.
        .fitOrScroll()
        .padding(24)
        .background(Color.paper.ignoresSafeArea())
        // The screen is one view whose content swaps in place, so VoiceOver would stay on an
        // element that vanished. Next, Back, Skip and every offer all change `step`, so one
        // screen-change notice covers them: focus moves to the new screen's first element, which is
        // its question or offer heading (#406).
        .onChange(of: step) { _, _ in AccessibilityNotification.ScreenChanged(nil).post() }
    }

    // MARK: Step 1 - the welcome screen, kept as it was

    private var welcome: some View {
        // 20pt between rows, not 28: the card fan is taller than the emoji it replaced, and
        // at 28 the screen no longer fit an everyday phone, so Start slid under the edge.
        VStack(spacing: 20) {
            Spacer()

            CardFan(slugs: ["dog", "teapot", "sunflower"])

            Text(AppLanguage.localized("app.title"))
                .font(.largeTitle.weight(.bold))
                .fontDesign(.serif)

            VStack(spacing: 12) {
                line(AppLanguage.localized("onboarding.line1"))
                line(AppLanguage.localized("onboarding.line2"))
                line(AppLanguage.localized("onboarding.line3"))
            }
            .padding(.horizontal, 8)

            Text(AppLanguage.localized("onboarding.disclaimer"))
                .font(.body)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)

            Spacer()

            languageChoice

            Button {
                next()
            } label: {
                Text(AppLanguage.localized("onboarding.start"))
            }
            .buttonStyle(RetroButtonStyle())
            .accessibilityHint(AppLanguage.localized("onboarding.start.hint"))
        }
    }

    // MARK: Steps 2-5 - one question each

    /// One question per screen. VoiceOver reads what is being asked first, then where the player
    /// is, then each answer with its state.
    private func questionStep(_ question: OnboardingQuestion) -> some View {
        VStack(spacing: 16) {
            stepDots

            Spacer(minLength: 0)

            Text(AppLanguage.localized(question.titleKey))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                // Read first, ahead of "2 of 5" above it, so the screen-change notice lands on
                // the question itself (#406).
                .accessibilitySortPriority(1)

            // Five answers one per row would push Next and Skip off an everyday screen, so the
            // multi-select question lays its tiles out two by two; every other question shows one
            // per row, and at bigger text sizes every question does, because the words need the
            // whole width. Each tile keeps its 100pt height either way (conventions §4).
            if question.allowsMultiple {
                LazyVGrid(columns: answerColumns, spacing: 10) {
                    answerTiles(question)
                }
            } else {
                VStack(spacing: 10) {
                    answerTiles(question)
                }
            }

            // The focus question takes more than one answer, so it is the only one that waits
            // for "Next" instead of moving on at the first tap.
            if question.allowsMultiple {
                Button {
                    next()
                } label: {
                    Text(AppLanguage.localized("onboarding.next"))
                }
                .buttonStyle(RetroButtonStyle())
            }

            Spacer(minLength: 0)

            footer
        }
        // The sort priority above only reorders within a container.
        .accessibilityElement(children: .contain)
    }

    /// One tile per answer, in the order the flow offers them. The chosen ones carry a tick and a
    /// filled background, never colour alone.
    @ViewBuilder
    private func answerTiles(_ question: OnboardingQuestion) -> some View {
        ForEach(OnboardingSteps.answers(for: question, profile: profile), id: \.labelKey) { answer in
            let chosen = OnboardingSteps.isChosen(answer, in: profile)
            Button {
                choose(answer, in: question)
            } label: {
                ProfileAnswerTile(text: AppLanguage.localized(answer.labelKey), chosen: chosen)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(chosen ? [.isSelected] : [])
        }
    }

    /// Two columns for the question that offers five answers, one column everywhere else and at
    /// accessibility text sizes, where two short columns would break the words in half.
    private var answerColumns: [GridItem] {
        typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
    }

    /// "2 of 5" and one dot per step: the words say where the player is, the dots show it,
    /// so the progress is never colour alone (conventions §4).
    private var stepDots: some View {
        VStack(spacing: 10) {
            Text(String(format: AppLanguage.localized("onboarding.step %lld %lld"), step, OnboardingSteps.stepCount))
                .font(.body)
                .foregroundStyle(Color.inkSoft)

            HStack(spacing: 10) {
                ForEach(1...OnboardingSteps.stepCount, id: \.self) { dot in
                    Circle()
                        .fill(dot <= step ? Color.brand : Color.clear)
                        .overlay(Circle().strokeBorder(Color.brand, lineWidth: 2))
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityHidden(true)
        }
    }

    /// Back and Skip, both 100pt and always on screen: leaving a question unanswered is as
    /// easy as answering it (#212).
    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                back()
            } label: {
                Text(AppLanguage.localized("onboarding.back"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))
            .accessibilityHint(AppLanguage.localized("onboarding.back.hint"))

            Button {
                next()
            } label: {
                Text(AppLanguage.localized("onboarding.skip"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))
            .accessibilityHint(AppLanguage.localized("onboarding.skip.hint"))
        }
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .multilineTextAlignment(.center)
    }

    /// Language is asked here rather than buried in settings: for a stranger,
    /// this is the one setting that must be right before anything else.
    private var languageChoice: some View {
        HStack(spacing: 12) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    AppLanguage.apply(language.rawValue)
                } label: {
                    Text(language.label)
                        .font(.title3.weight(language.rawValue == appLanguage ? .bold : .regular))
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background {
                            ZStack {
                                Color.paper
                                if language.rawValue == appLanguage { Color.brand.opacity(0.22) }
                            }
                            .clipShape(.rect(cornerRadius: 16))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    language.rawValue == appLanguage ? Color.brand : Color.espresso,
                                    lineWidth: language.rawValue == appLanguage ? 3 : 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.label)
                .accessibilityAddTraits(language.rawValue == appLanguage ? [.isSelected] : [])
            }
        }
    }

    // MARK: After the questions - family photos (#374)

    /// Offered once, while the album is empty: three games use the family's own photos. Add and
    /// Later are the same size, so passing is as easy as adding, and nothing here is a step.
    private var photosOffer: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Text(AppLanguage.localized("onboarding.photos.title"))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(AppLanguage.localized("onboarding.photos.body"))
                .font(.title3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let photoNote {
                Text(photoNote)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            if picked.isEmpty {
                PhotosPicker(selection: $picked, maxSelectionCount: MemoryPhotos.maxCount, matching: .images) {
                    Label(AppLanguage.localized("family.photos.add"), systemImage: "photo.on.rectangle.angled")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .foregroundStyle(Color.paper)
                        .background(Color.brand, in: .rect(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLanguage.localized("family.photos.add"))
                .accessibilityHint(AppLanguage.localized("onboarding.photos.add.hint"))
            } else {
                // The photos are being shrunk and stored; the spinner holds the button's place.
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }

            Button {
                next()
            } label: {
                Text(AppLanguage.localized("onboarding.photos.later"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))
            .accessibilityLabel(AppLanguage.localized("onboarding.photos.later"))
            .accessibilityHint(AppLanguage.localized("onboarding.photos.later.hint"))

            Spacer(minLength: 0)

            Button {
                back()
            } label: {
                Text(AppLanguage.localized("onboarding.back"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))
            .accessibilityHint(AppLanguage.localized("onboarding.back.hint"))
        }
        .disabled(!picked.isEmpty)
        // Same import as Set up (#120); a task, so leaving mid-pick cancels it.
        .task(id: picked) {
            let items = picked
            guard !items.isEmpty, let imported = await FamilyPhotoImport.run(items) else { return }
            picked = []
            if imported.added.isEmpty {
                photoNote = imported.result.note
                if let photoNote { AccessibilityNotification.Announcement(photoNote).post() }
            } else {
                photoNote = nil
                toName = imported.added
                nameNextPhoto()
            }
        }
        .sheet(item: $naming, onDismiss: nameNextPhoto) { target in
            FamilyPhotoCaptionSheet(photo: target.url, promptKey: "game.reminiscence.prompt.photo") {}
        }
    }

    /// One name sheet per new photo, in order. Done without a name is fine: the photo stays and
    /// can be named later in Set up. After the last one the first run goes on.
    private func nameNextPhoto() {
        guard !toName.isEmpty else {
            if offer == .photos { next() }
            return
        }
        naming = CaptionTarget(url: toName.removeFirst())
    }

    // MARK: After the questions - the warm-up offer (#213)

    /// Offered once, after the last question, and only to someone playing for themselves. Two
    /// big buttons and nothing else: no score is promised and none is shown afterwards.
    private var warmUpOffer: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Text(AppLanguage.localized("warmup.offer.title"))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Button {
                WarmUpStore.start(profile: profile, today: PlanStore.dayStamp())
                hasSeenOnboarding = true
            } label: {
                Text(AppLanguage.localized("warmup.accept"))
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .foregroundStyle(Color.paper)
                    .background(Color.brand, in: .rect(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityHint(AppLanguage.localized("warmup.accept.hint"))

            Button {
                hasSeenOnboarding = true
            } label: {
                Text(AppLanguage.localized("warmup.notnow"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))

            Spacer(minLength: 0)

            Button {
                back()
            } label: {
                Text(AppLanguage.localized("onboarding.back"))
                    .font(.title2)
            }
            .buttonStyle(AnswerTileStyle(strength: 0.10))
            .accessibilityHint(AppLanguage.localized("onboarding.back.hint"))
        }
    }

    // MARK: Answers

    /// Answers save as they are given, so a flow left half-way keeps what was answered. A
    /// question that takes one answer moves on at the tap; the others wait for Next.
    private func choose(_ answer: ProfileAnswer, in question: OnboardingQuestion) {
        profile = OnboardingSteps.choosing(answer, in: profile)
        ProfileStore.save(profile)
        if !question.allowsMultiple { next() }
    }

    /// Forward: the next question, then the offers that apply (#374, #213), then Home. Skip
    /// calls this too, leaving the profile exactly as it is.
    private func next() {
        if step == OnboardingSteps.stepCount {
            offers = OnboardingSteps.afterQuestions(albumCount: MemoryPhotos.all().count, profile: profile)
        }
        if step < OnboardingSteps.stepCount + offers.count {
            step += 1
        } else {
            hasSeenOnboarding = true
        }
    }

    /// Back: the previous question, or the welcome screen.
    private func back() {
        step = max(1, step - 1)
    }
}

#Preview {
    OnboardingView()
}
