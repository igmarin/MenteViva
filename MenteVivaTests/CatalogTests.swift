import XCTest

/// #410: "every string in EN + ES" holds for the whole catalog, not only where a feature wrote its own test.
/// The walk is a pure function over the parsed catalog, so the hand-built catalogs below prove it can fail.
final class CatalogTests: XCTestCase {
    enum Kind { case text, form, specifiers }

    /// Every problem in `strings` (the catalog's `strings` object), one per key, language and form.
    /// Deliberate choices, from how this catalog behaves in the app:
    /// - Keys here are identifiers, so a missing `en` would show the raw key: `en` and `es` are both required
    ///   explicitly, even for an entry with no `localizations` at all.
    /// - No exemptions: `shouldTranslate: false` and `extractionState: stale` keys are checked like any other.
    /// - A plural (or device) form must exist in both languages, even one a language never uses (Spanish `many`).
    /// - Specifiers are compared per form as (position, type): `%@ %lld` against `%lld %@` fails, an explicit
    ///   reorder (`%2$lld ... %1$@`) passes, and `%%` is a literal percent, not a specifier.
    static func problems(in strings: [String: Any]) -> [(kind: Kind, text: String)] {
        var found: [(kind: Kind, text: String)] = []
        for (key, entry) in strings.sorted(by: { $0.key < $1.key }) {
            let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any] ?? [:]
            let languages = ["en", "es"]
            let texts = languages.map { leaves(localizations[$0] as? [String: Any] ?? [:], path: "") }
            func label(_ i: Int, _ form: String) -> String { "\(key) [\(languages[i])]" + (form.isEmpty ? "" : " \(form)") }
            for i in 0...1 {
                if texts[i].isEmpty { found.append((.text, "\(label(i, "")): no text")) }
                for (form, value) in texts[i].sorted(by: { $0.key < $1.key }) {
                    if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        found.append((.text, "\(label(i, form)): empty"))
                    }
                    if !texts[1 - i].isEmpty, texts[1 - i][form] == nil {
                        found.append((.form, "\(label(1 - i, form)): form missing"))
                    }
                }
            }
            for (form, english) in texts[0] {
                guard let spanish = texts[1][form], specifiers(english) != specifiers(spanish) else { continue }
                found.append((.specifiers, "\(label(1, form)): \(specifiers(spanish)) but en has \(specifiers(english))"))
            }
        }
        return found
    }

    /// The text of one localization by form: "" for a plain `stringUnit`, "plural.one", nested "device.iphone.plural.one".
    private static func leaves(_ node: [String: Any], path: String) -> [String: String] {
        if let unit = node["stringUnit"] as? [String: Any] { return [path: unit["value"] as? String ?? ""] }
        var result: [String: String] = [:]
        for (kind, forms) in node["variations"] as? [String: [String: Any]] ?? [:] {
            for (form, sub) in forms {
                let formPath = (path.isEmpty ? "" : path + ".") + "\(kind).\(form)"
                result.merge(leaves(sub as? [String: Any] ?? [:], path: formPath)) { first, _ in first }
            }
        }
        return result
    }

    /// "1$@ 2$lld": implicit specifiers numbered by order, explicit ones by their own position, sorted.
    /// The length modifier stays in the type, so `%d` and `%lld` differ (they read different argument widths).
    private static func specifiers(_ text: String) -> String {
        let pattern = #"%(?:(\d+)\$)?[-+#0]*\d*(?:\.\d+)?((?:hh|h|ll|l|q|L|z|t|j)?[@dDiuUxXoOfFeEgGcCsSpaA%])"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let ns = text as NSString
        var found: [String] = []
        for match in regex?.matches(in: text, range: NSRange(location: 0, length: ns.length)) ?? [] {
            let type = ns.substring(with: match.range(at: 2))
            let explicit = match.range(at: 1)
            let position = explicit.location == NSNotFound ? "\(found.count + 1)" : ns.substring(with: explicit)
            if type != "%" { found.append("\(position)$\(type)") }
        }
        return found.sorted().joined(separator: " ")
    }

    private func realCatalog() throws -> [String: Any] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        XCTAssertFalse(strings.isEmpty, "an empty catalog would pass the walk")
        return strings
    }

    private func unit(_ value: String) -> [String: Any] { ["stringUnit": ["state": "translated", "value": value]] }
    private func plural(_ forms: [String: String]) -> [String: Any] { ["variations": ["plural": forms.mapValues(unit)]] }
    private func catalog(en: [String: Any], es: [String: Any]?) -> [String: Any] {
        ["key": ["localizations": ["en": en, "es": es].compactMapValues { $0 }]]
    }

    private func texts(_ kind: Kind, in strings: [String: Any]) -> [String] {
        Self.problems(in: strings).filter { $0.kind == kind }.map(\.text)
    }

    func testGivenEveryCatalogKeyWhenReadThenEnAndEsAreNonEmpty() throws {
        XCTAssertEqual(texts(.text, in: try realCatalog()), [])
    }

    func testGivenPluralVariationsWhenReadThenEveryFormHasEnAndEs() throws {
        XCTAssertEqual(texts(.form, in: try realCatalog()), [])
    }

    func testGivenEnAndEsValuesWhenComparedThenFormatSpecifiersMatch() throws {
        XCTAssertEqual(texts(.specifiers, in: try realCatalog()), [])
    }

    func testGivenAKeyWithOnlyEnWhenWalkedThenItFailsNamingKeyAndLanguage() {
        XCTAssertEqual(texts(.text, in: catalog(en: unit("Hi"), es: nil)), ["key [es]: no text"])
        XCTAssertEqual(texts(.text, in: ["bare": [String: Any]()]), ["bare [en]: no text", "bare [es]: no text"])
        XCTAssertEqual(texts(.text, in: catalog(en: unit("Hi"), es: unit("  "))), ["key [es]: empty"])
    }

    func testGivenAPluralKeyMissingAnEsFormWhenWalkedThenItFailsNamingKeyAndForm() {
        let strings = catalog(en: plural(["one": "%lld game", "other": "%lld games"]), es: plural(["other": "%lld juegos"]))
        XCTAssertEqual(texts(.form, in: strings), ["key [es] plural.one: form missing"])
    }

    func testGivenAnEsValueWithADifferentSpecifierWhenWalkedThenItFailsNamingKey() {
        let problems = texts(.specifiers, in: catalog(en: unit("%lld games"), es: unit("%@ juegos")))
        XCTAssertEqual(problems, ["key [es]: 1$@ but en has 1$lld"])
    }

    func testGivenAReorderedValueWithLiteralPercentWhenWalkedThenItPasses() {
        let strings = catalog(en: unit("%@ has %lld, 50%% done"), es: unit("%2$lld tiene %1$@, 50%% listo"))
        XCTAssertEqual(Self.problems(in: strings).count, 0)
    }

    func testGivenSwappedOrNarrowedSpecifiersWhenWalkedThenItFails() {
        for (en, es) in [("%@ has %lld", "%lld tiene %@"), ("%lld games", "%d juegos")] {
            XCTAssertEqual(texts(.specifiers, in: catalog(en: unit(en), es: unit(es))).count, 1, en)
        }
    }
}
