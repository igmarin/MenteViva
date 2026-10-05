import Foundation

/// Reads the signpost intervals out of an Instruments `.trace` and prints each
/// `HotPath` name against the budget, so a slow one is a line of output rather
/// than something you have to spot by eye in the Points of Interest lane.
/// Exits 1 when any interval is over budget.
///
///     swift tools/signpost_budget.swift <trace> [budget-ms]
///
/// `tools/profile.sh` runs this for you. See docs/profiling.md.

let subsystem = "com.igmarin.MenteViva"
let defaultBudgetMilliseconds = 100.0

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    fail("Usage: swift tools/signpost_budget.swift <trace> [budget-ms]")
}
let tracePath = arguments[1]
let budget = arguments.count >= 3 ? (Double(arguments[2]) ?? defaultBudgetMilliseconds) : defaultBudgetMilliseconds

/// The paired start/duration table; the raw `os-signpost` one would need
/// Begin and End rows matched up by hand.
func exportedIntervals(from trace: String) -> String {
    let xctrace = Process()
    xctrace.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    xctrace.arguments = [
        "xctrace", "export", "--input", trace,
        "--xpath", #"/trace-toc/run[@number="1"]/data/table[@schema="OSSignpostIntervals"]"#,
    ]
    let pipe = Pipe()
    xctrace.standardOutput = pipe
    xctrace.standardError = FileHandle.nullDevice
    do {
        try xctrace.run()
    } catch {
        fail("Could not run xctrace: \(error.localizedDescription)")
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    xctrace.waitUntilExit()
    guard xctrace.terminationStatus == 0 else { fail("xctrace could not export \(trace).") }
    return String(decoding: data, as: UTF8.self)
}

let document: XMLDocument
do {
    document = try XMLDocument(xmlString: exportedIntervals(from: tracePath))
} catch {
    fail("That trace did not export as XML: \(error.localizedDescription)")
}

/// xctrace writes each value once carrying an `id`, then repeats it as a bare
/// `ref` to that id, so every lookup has to go through this table.
var valuesByID: [String: XMLElement] = [:]
for case let element as XMLElement in (try? document.nodes(forXPath: "//*[@id]")) ?? [] {
    if let id = element.attribute(forName: "id")?.stringValue { valuesByID[id] = element }
}

/// The row's own column of that name, never one nested inside another column.
func column(_ name: String, of row: XMLElement) -> String? {
    guard let cell = row.elements(forName: name).first else { return nil }
    guard let ref = cell.attribute(forName: "ref")?.stringValue else { return cell.stringValue }
    return valuesByID[ref]?.stringValue
}

struct Interval {
    let name: String
    let milliseconds: Double
}

var intervals: [Interval] = []
for case let row as XMLElement in (try? document.nodes(forXPath: "//row")) ?? [] {
    guard let name = column("signpost-name", of: row),
        column("subsystem", of: row) == subsystem,
        let nanoseconds = Double(column("duration", of: row) ?? "")
    else { continue }
    intervals.append(Interval(name: name, milliseconds: nanoseconds / 1_000_000))
}

guard !intervals.isEmpty else {
    print("")
    print("No \(subsystem) signposts in this trace.")
    print("Play a flow that reaches one while recording; docs/profiling.md lists them.")
    exit(0)
}

func padded(_ text: String, _ width: Int) -> String {
    text.count >= width ? text : text + String(repeating: " ", count: width - text.count)
}

func milliseconds(_ value: Double) -> String {
    String(format: "%.2f ms", value)
}

let worstByName = Dictionary(grouping: intervals, by: \.name)
    .mapValues { $0.map(\.milliseconds).sorted() }
var anyOverBudget = false

print("")
print("Signpost intervals, budget \(Int(budget)) ms:")
for (name, times) in worstByName.sorted(by: { ($0.value.last ?? 0) > ($1.value.last ?? 0) }) {
    let worst = times.last ?? 0
    let median = times[times.count / 2]
    anyOverBudget = anyOverBudget || worst > budget
    print(
        "  \(padded(worst > budget ? "OVER" : "ok", 5))\(padded(name, 22))"
            + "\(padded("\(times.count) run(s)", 10))median \(padded(milliseconds(median), 11))worst \(milliseconds(worst))")
}

if anyOverBudget {
    print("")
    print("Over \(Int(budget)) ms while someone is waiting is a bug (docs/profiling.md).")
    print("Open the trace and read the Time Profiler call tree over that interval.")
    exit(1)
}
exit(0)
