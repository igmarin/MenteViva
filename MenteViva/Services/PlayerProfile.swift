import Foundation

/// What onboarding asks (#211): who plays, what they'd like to exercise, how long a day and how to
/// start. Every answer is optional so every question can be skipped; there is no age and no free text.
/// `DailyPolicy` turns it into the plan, on the device; nothing leaves it.
nonisolated struct PlayerProfile: Codable, Equatable {
    enum ForWhom: String, Codable { case me, familyMember }

    /// What a game mostly exercises (it exercises, never "improves": decisions.md 2026-10-26).
    /// `.justFun` is a real answer that means "no preference", so it changes nothing.
    enum Focus: String, Codable, CaseIterable { case memory, attention, numbers, words, justFun }

    enum StartPace: String, Codable { case calm, normal, challenge }

    var forWhom: ForWhom?
    /// Empty means no preference.
    var focus: Set<Focus> = []
    /// 5, 10 or 15; any other value reads as unset.
    var minutesPerDay: Int?
    var startPace: StartPace?
}

nonisolated extension PlayerProfile {
    /// One missing or unreadable answer falls back alone; the player's other answers stay.
    init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            forWhom: (try? fields.decodeIfPresent(ForWhom.self, forKey: .forWhom)) ?? nil,
            focus: (try? fields.decodeIfPresent(Set<Focus>.self, forKey: .focus)) ?? [],
            minutesPerDay: (try? fields.decodeIfPresent(Int.self, forKey: .minutesPerDay)) ?? nil,
            startPace: (try? fields.decodeIfPresent(StartPace.self, forKey: .startPace)) ?? nil)
    }
}

/// Keeps the `PlayerProfile` in UserDefaults, injected so tests use their own suite. A missing or
/// unreadable profile is the empty one, and an empty profile leaves the plan exactly as it was.
nonisolated enum ProfileStore {
    static let key = "profile.player"

    static func load(defaults: UserDefaults = .standard) -> PlayerProfile {
        guard let data = defaults.data(forKey: key),
            let profile = try? JSONDecoder().decode(PlayerProfile.self, from: data)
        else { return PlayerProfile() }
        return profile
    }

    static func save(_ profile: PlayerProfile, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: key)
        }
    }
}
