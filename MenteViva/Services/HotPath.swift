import OSLog

/// Marks a hot path so Instruments can time it (Points of Interest / os_signpost).
/// Costs next to nothing when no profiler is attached, so it ships in release
/// builds too. Wrap only work that can be slow or runs on every redraw.
///
///     let small = HotPath.measure("photo.downscale") { ... }
///
/// How to read the results: docs/profiling.md.
enum HotPath {
    private static let signposter = OSSignposter(subsystem: "com.igmarin.MenteViva", category: .pointsOfInterest)

    /// Runs `body` inside a signpost interval named `name`.
    static func measure<T>(_ name: StaticString, _ body: () throws -> T) rethrows -> T {
        let state = signposter.beginInterval(name)
        defer { signposter.endInterval(name, state) }
        return try body()
    }
}
