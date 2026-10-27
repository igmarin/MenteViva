#!/usr/bin/env swift  // Generates MenteViva.xcodeproj from the files on disk. No external deps.  // Re-run after adding source files: swift tools/generate_project.swift
import Foundation

/// Fail with one clear line instead of a raw trace.
func die(_ message: String) -> Never {
    FileHandle.standardError.write(Data("generate_project: \(message)\n".utf8))
    exit(1)
}

// Resolve the repo root from this script's location (tools/ -> repo root), not
// from the cwd, so running it from anywhere gives the same output.
let scriptPath =
    CommandLine.arguments.first { $0.hasSuffix("generate_project.swift") }
    ?? "tools/generate_project.swift"
let root = URL(fileURLWithPath: scriptPath).standardizedFileURL
    .deletingLastPathComponent().deletingLastPathComponent()
let appDir = root.appendingPathComponent("MenteViva")
guard FileManager.default.fileExists(atPath: appDir.path) else {
    die("no MenteViva/ source folder at \(root.path). Run it as: swift tools/generate_project.swift")
}

/// CloudKit is **off by default** until the paid Developer Program is bought
/// (decisions.md 2026-09-20). A CloudKit-enabled build without the iCloud
/// entitlement traps at launch on device, and the simulator does not reproduce
/// it, so the safe default is the one that works for a free Apple ID.
///
///   swift tools/generate_project.swift            # local-only (default)
///   swift tools/generate_project.swift --cloudkit # opt in later, with the
///                                                 # paid account + container
let cloudKit = CommandLine.arguments.contains("--cloudkit")
let localOnly = !cloudKit

/// Signing team, pre-filled so device builds never stop to ask.
/// Ismael Marin Cabrera (Personal Team) — free provisioning, so installs on a
/// device expire 7 days after signing. Verified against the installed
/// provisioning profile for com.igmarin.MenteViva (TeamIdentifier VB42T7NYX2).
/// Override without editing: MENTEVIVA_TEAM=XXXXXXXXXX swift tools/generate_project.swift
/// (or change the default when the paid team replaces it).
let developmentTeam = ProcessInfo.processInfo.environment["MENTEVIVA_TEAM"] ?? "VB42T7NYX2"
let testsDir = root.appendingPathComponent("MenteVivaTests")

/// All .swift files under `dir`, paths relative to `base`.
func swiftFiles(under dir: URL, relativeTo base: URL) -> [String] {
    guard let enumerator = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: nil) else { return [] }
    var files: [String] = []
    for case let url as URL in enumerator where url.pathExtension == "swift" {
        files.append(url.path.replacingOccurrences(of: base.path + "/", with: ""))
    }
    return files.sorted()
}

let appFiles = swiftFiles(under: appDir, relativeTo: appDir)
let testFiles = swiftFiles(under: testsDir, relativeTo: root)  // "MenteVivaTests/…"

// Stable, deterministic IDs: FNV-1a hash → 24 hex chars.
func oid(_ s: String) -> String {
    var h: UInt64 = 0xcbf2_9ce4_8422_2325
    for b in s.utf8 { h = (h ^ UInt64(b)) &* 0x100_0000_01b3 }
    return String(format: "%016llX%08X", h, UInt32(s.count))
}

let appID = oid("MenteViva.app")
let grpID = oid("group")
let srcsID = oid("Sources")
let rootGrpID = oid("rootGroup")
let productsGrpID = oid("productsGroup")
let resID = oid("Resources")
let fwID = oid("Frameworks")
let pbxID = oid("proj")
let tgtID = oid("target")
let catID = oid("xcstrings")
let catBuildID = oid("xcstrings.build")
let assetsID = oid("Assets.xcassets")
let assetsBuildID = oid("Assets.xcassets.build")
let entID = oid("entitlements")

// Test-target IDs (salted so they can never collide with app file hashes).
let testsProductID = oid("MenteVivaTests.xctest")
let testsTgtID = oid("tests:target")
let testsSrcsID = oid("tests:Sources")
let testsFwID = oid("tests:Frameworks")
let testsResID = oid("tests:Resources")
let testsGrpID = oid("tests:group")
let testsDepID = oid("tests:dep")
let testsProxyID = oid("tests:proxy")
var fileRefs = ""
var buildFiles = ""
var children = ""
var phaseFiles = ""
for f in appFiles {
    let ref = oid(f)
    let bld = oid(f + ".build")
    let name = URL(fileURLWithPath: f).lastPathComponent
    fileRefs +=
        "\t\t\(ref) /* \(name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \(f); sourceTree = \"<group>\"; };\n"
    buildFiles += "\t\t\(bld) /* \(name) in Sources */ = {isa = PBXBuildFile; fileRef = \(ref); };\n"
    children += "\t\t\t\t\(ref) /* \(name) */,\n"
    phaseFiles += "\t\t\t\t\(bld) /* \(name) in Sources */,\n"
}

/// File refs / build files / sources-phase entries for a test bundle.
/// Paths are root-relative, sourceTree SOURCE_ROOT, so nested folders work.
func testSections(_ files: [String], salt: String) -> (refs: String, builds: String, phase: String, kids: String) {
    var refs = ""
    var builds = ""
    var phase = ""
    var kids = ""
    for f in files {
        let ref = oid(salt + f)
        let bld = oid(salt + f + ".build")
        let name = URL(fileURLWithPath: f).lastPathComponent
        refs +=
            "\t\t\(ref) /* \(name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \(f); sourceTree = SOURCE_ROOT; };\n"
        builds += "\t\t\(bld) /* \(name) in Sources */ = {isa = PBXBuildFile; fileRef = \(ref); };\n"
        phase += "\t\t\t\t\(bld) /* \(name) in Sources */,\n"
        kids += "\t\t\t\t\(ref) /* \(name) */,\n"
    }
    return (refs, builds, phase, kids)
}

let tests = testSections(testFiles, salt: "tests:")
let hasTests = !testFiles.isEmpty

var p = """
    // !$*UTF8*$!
    {
    \tarchiveVersion = 1;
    \tclasses = {
    \t};
    \tobjectVersion = 90;
    \tobjects = {

    """
p += buildFiles + tests.builds + "\n" + fileRefs + tests.refs
p +=
    "\t\t\(appID) /* MenteViva.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MenteViva.app; sourceTree = BUILT_PRODUCTS_DIR; };\n"
p +=
    "\t\t\(catID) /* Localizable.xcstrings */ = {isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = Localizable.xcstrings; sourceTree = \"<group>\"; };\n\n"
if !localOnly {
    p +=
        "\t\t\(entID) /* MenteViva.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = MenteViva.entitlements; sourceTree = \"<group>\"; };\n"
}
p += "\t\t\(catBuildID) /* Localizable.xcstrings in Resources */ = {isa = PBXBuildFile; fileRef = \(catID); };\n"
p +=
    "\t\t\(assetsID) /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; };\n"
p += "\t\t\(assetsBuildID) /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = \(assetsID); };\n\n"
if hasTests {
    p +=
        "\t\t\(testsProductID) /* MenteVivaTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MenteVivaTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };\n"
}
p += "\n"

// MARK: Groups

// Root group + Products group: Xcode expects a container group holding the
// source group and a Products group holding built products. Without them the
// GUI reports a "file format integrity issue" even though xcodebuild parses fine.
var productsChildren = "\t\t\t\t\(appID) /* MenteViva.app */,\n"
if hasTests { productsChildren += "\t\t\t\t\(testsProductID) /* MenteVivaTests.xctest */,\n" }
p +=
    "\t\t\(rootGrpID) = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = ( \(grpID) /* MenteViva */, \(productsGrpID) /* Products */ );\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n"
p +=
    "\t\t\(productsGrpID) /* Products */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\(productsChildren)\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n\n"

p +=
    "\t\t\(grpID) /* MenteViva */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\(children)"
    + (localOnly ? "" : "\t\t\t\t\(entID) /* MenteViva.entitlements */,\n")
    + "\t\t\t\t\(catID) /* Localizable.xcstrings */,\n\t\t\t\t\(assetsID) /* Assets.xcassets */,\n"
if hasTests { p += "\t\t\t\t\(testsGrpID) /* MenteVivaTests */,\n" }
p += "\t\t\t);\n\t\t\tpath = MenteViva;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n\n"
if hasTests {
    p +=
        "\t\t\(testsGrpID) /* MenteVivaTests */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\(tests.kids)\t\t\t);\n\t\t\tname = MenteVivaTests;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n\n"
}

// MARK: Targets + dependencies

p +=
    "\t\t\(tgtID) /* MenteViva */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = \(oid("tgtCfgList")) /* Build configuration list for PBXNativeTarget \"MenteViva\" */;\n\t\t\tbuildPhases = ( \(srcsID) /* Sources */, \(fwID) /* Frameworks */, \(resID) /* Resources */ );\n\t\t\tbuildRules = ( );\n\t\t\tdependencies = ( );\n\t\t\tname = MenteViva;\n\t\t\tproductName = MenteViva;\n\t\t\tproductReference = \(appID);\n\t\t\tproductType = \"com.apple.product-type.application\";\n\t\t};\n\n"
if hasTests {
    p +=
        "\t\t\(testsTgtID) /* MenteVivaTests */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = \(oid("tests:cfgList")) /* Build configuration list for PBXNativeTarget \"MenteVivaTests\" */;\n\t\t\tbuildPhases = ( \(testsSrcsID) /* Sources */, \(testsFwID) /* Frameworks */, \(testsResID) /* Resources */ );\n\t\t\tbuildRules = ( );\n\t\t\tdependencies = ( \(testsDepID) /* PBXTargetDependency */ );\n\t\t\tname = MenteVivaTests;\n\t\t\tproductName = MenteVivaTests;\n\t\t\tproductReference = \(testsProductID);\n\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";\n\t\t};\n\n"
    p +=
        "\t\t\(testsProxyID) /* PBXContainerItemProxy */ = { isa = PBXContainerItemProxy; containerPortal = \(pbxID) /* Project object */; proxyType = 1; remoteGlobalIDString = \(tgtID); remoteInfo = MenteViva; };\n"
    p +=
        "\t\t\(testsDepID) /* PBXTargetDependency */ = { isa = PBXTargetDependency; target = \(tgtID) /* MenteViva */; targetProxy = \(testsProxyID); };\n\n"
}

// MARK: Project

var targetAttrs = "\(tgtID) = { CreatedOnToolsVersion = 16.0; };"
if hasTests { targetAttrs += " \(testsTgtID) = { CreatedOnToolsVersion = 16.0; TestTargetID = \(tgtID); };" }
var targetsList = "\(tgtID) /* MenteViva */"
if hasTests { targetsList += ", \(testsTgtID) /* MenteVivaTests */" }

p +=
    "\t\t\(pbxID) /* Project object */ = {\n\t\t\tisa = PBXProject;\n\t\t\tattributes = { BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2630; LastUpgradeCheck = 2700; TargetAttributes = { \(targetAttrs) }; };\n\t\t\tbuildConfigurationList = \(oid("prjCfgList")) /* Build configuration list for PBXProject \"MenteViva\" */;\n\t\t\tdevelopmentRegion = en;\n\t\t\thasScannedForEncodings = 0;\n\t\t\tknownRegions = ( en, Base, es );\n\t\t\tmainGroup = \(rootGrpID);\n\t\t\tminimizedProjectReferenceProxies = 1;\n\t\t\tpreferredProjectObjectVersion = 90;\n\t\t\tproductRefGroup = \(productsGrpID) /* Products */;\n\t\t\tprojectDirPath = \"\";\n\t\t\tprojectRoot = \"\";\n\t\t\ttargets = ( \(targetsList) );\n\t\t};\n\n"

// MARK: Build phases

p +=
    "\t\t\(resID) /* Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = ( \(catBuildID) /* Localizable.xcstrings in Resources */, \(assetsBuildID) /* Assets.xcassets in Resources */ );\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\n"
p +=
    "\t\t\(fwID) /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = ( );\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\n"
p +=
    "\t\t\(srcsID) /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\(phaseFiles)\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\n"
if hasTests {
    p +=
        "\t\t\(testsSrcsID) /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\(tests.phase)\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\n"
    p +=
        "\t\t\(testsFwID) /* Frameworks */ = { isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0; };\n"
    p +=
        "\t\t\(testsResID) /* Resources */ = { isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0; };\n\n"
}

// MARK: Build configurations

/// One XCBuildConfiguration block. Values are emitted verbatim — quote at call site.
func configBlock(_ name: String, owner: String, settings: [(String, String)]) -> String {
    var s = "\t\t\(oid("cfg:\(owner):\(name)")) /* \(name) */ = {\n\t\t\tisa = XCBuildConfiguration;\n"
    s += "\t\t\tbuildSettings = {\n"
    for (k, v) in settings { s += "\t\t\t\t\(k) = \(v);\n" }
    s += "\t\t\t};\n\t\t\tname = \(name);\n\t\t};\n"
    return s
}

func configList(_ id: String, _ owner: String) -> String {
    "\t\t\(id) = { isa = XCConfigurationList; buildConfigurations = ( \(oid("cfg:\(owner):Debug")), \(oid("cfg:\(owner):Release")) ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };\n"
}

/// Project-level settings. Mirrors the recommended set Xcode 27 puts in a new
/// project (read from IDEFoundation's app-project prototype, objectVersion 90) —
/// adopting it is what stops the "Update to recommended settings" prompt.
let projectCommon: [(String, String)] = [
    ("ALWAYS_SEARCH_USER_PATHS", "NO"),
    ("ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS", "YES"),
    ("CLANG_ANALYZER_NONNULL", "YES"),
    ("CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION", "YES_AGGRESSIVE"),
    ("CLANG_ENABLE_MODULES", "YES"),
    ("CLANG_ENABLE_OBJC_ARC", "YES"),
    ("CLANG_ENABLE_OBJC_WEAK", "YES"),
    ("CLANG_WARN_BOOL_CONVERSION", "YES"),
    ("CLANG_WARN_CONSTANT_CONVERSION", "YES"),
    ("CLANG_WARN_EMPTY_BODY", "YES"),
    ("CLANG_WARN_ENUM_CONVERSION", "YES"),
    ("CLANG_WARN_INFINITE_RECURSION", "YES"),
    ("CLANG_WARN_INT_CONVERSION", "YES"),
    ("CLANG_WARN_UNREACHABLE_CODE", "YES"),
    ("COPY_PHASE_STRIP", "NO"),
    ("DEAD_CODE_STRIPPING", "YES"),
    ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
    ("ENABLE_USER_SCRIPT_SANDBOXING", "YES"),
    ("GCC_NO_COMMON_BLOCKS", "YES"),
    ("GCC_WARN_UNINITIALIZED_AUTOS", "YES_AGGRESSIVE"),
    ("GCC_WARN_UNUSED_FUNCTION", "YES"),
    ("GCC_WARN_UNUSED_VARIABLE", "YES"),
    ("LOCALIZATION_PREFERS_STRING_CATALOGS", "YES"),
    ("STR_CATALOG_GENERATE_SYMBOLS", "YES"),
    ("SWIFT_VERSION", "5.0"),
]

let projectDebug =
    projectCommon + [
        ("DEBUG_INFORMATION_FORMAT", "dwarf"),
        ("ENABLE_TESTABILITY", "YES"),
        ("GCC_OPTIMIZATION_LEVEL", "0"),
        ("GCC_PREPROCESSOR_DEFINITIONS", "\"DEBUG=1 $(inherited)\""),
        ("ONLY_ACTIVE_ARCH", "YES"),
        ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "\"DEBUG $(inherited)\""),
        ("SWIFT_OPTIMIZATION_LEVEL", "\"-Onone\""),
    ]

let projectRelease =
    projectCommon + [
        ("DEBUG_INFORMATION_FORMAT", "\"dwarf-with-dsym\""),
        ("ENABLE_NS_ASSERTIONS", "NO"),
        ("SWIFT_COMPILATION_MODE", "wholemodule"),
        ("SWIFT_OPTIMIZATION_LEVEL", "\"-O\""),
    ]

let common: [(String, String)] = [
    ("SDKROOT", "iphoneos"),
    ("SWIFT_VERSION", "5.0"),
    ("ENABLE_PREVIEWS", "YES"),
    ("CODE_SIGN_STYLE", "Automatic"),
    ("DEVELOPMENT_TEAM", "\"\(developmentTeam)\""),
    ("IPHONEOS_DEPLOYMENT_TARGET", "17.0"),
    ("TARGETED_DEVICE_FAMILY", "\"1,2\""),
]

let appSettings =
    common + [
        ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
        ("CODE_SIGN_ENTITLEMENTS", "MenteViva/MenteViva.entitlements"),
        // Compile-time switch for CloudKit. An INFOPLIST_KEY_* flag looked cleaner
        // but Xcode only injects a known allowlist of keys, so the value silently
        // vanished and the app enabled CloudKit against its own entitlements —
        // trapping inside CloudKit's mirroring setup on device (uncaught, EXC_BREAKPOINT).
        ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", localOnly ? "\"$(inherited) LOCAL_ONLY\"" : "\"$(inherited)\""),
        ("CURRENT_PROJECT_VERSION", "1"),
        ("GENERATE_INFOPLIST_FILE", "YES"),
        ("INFOPLIST_KEY_CFBundleDisplayName", "\"Mente Viva\""),
        ("INFOPLIST_KEY_UIApplicationSceneManifest_Generation", "YES"),
        ("INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents", "YES"),
        ("INFOPLIST_KEY_UILaunchScreen_Generation", "YES"),
        ("INFOPLIST_KEY_UIStatusBarStyle", "UIStatusBarStyleDefault"),
        (
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad",
            "\"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\""
        ),
        (
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone",
            "\"UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\""
        ),
        ("LD_RUNPATH_SEARCH_PATHS", "\"$(inherited) @executable_path/Frameworks\""),
        ("MARKETING_VERSION", "0.1.0"),
        ("PRODUCT_BUNDLE_IDENTIFIER", "com.igmarin.MenteViva"),
        ("PRODUCT_NAME", "\"$(TARGET_NAME)\""),
        ("STRING_CATALOG_GENERATE_SYMBOLS", "YES"),
        ("SUPPORTED_PLATFORMS", "\"iphoneos iphonesimulator\""),
        ("SWIFT_APPROACHABLE_CONCURRENCY", "YES"),
        ("SWIFT_DEFAULT_ACTOR_ISOLATION", "MainActor"),
        ("SWIFT_EMIT_LOC_STRINGS", "YES"),
        ("SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY", "YES"),
    ]

let testSettings =
    common + [
        ("BUNDLE_LOADER", "\"$(TEST_HOST)\""),
        ("TEST_HOST", "\"$(BUILT_PRODUCTS_DIR)/MenteViva.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MenteViva\""),
        ("GENERATE_INFOPLIST_FILE", "YES"),
        ("LD_RUNPATH_SEARCH_PATHS", "\"$(inherited) @executable_path/Frameworks @loader_path/Frameworks\""),
        ("PRODUCT_BUNDLE_IDENTIFIER", "com.igmarin.MenteVivaTests"),
        ("PRODUCT_NAME", "\"$(TARGET_NAME)\""),
        ("SWIFT_EMIT_LOC_STRINGS", "NO"),
    ]

p += configBlock("Debug", owner: "proj", settings: projectDebug)
p += configBlock("Release", owner: "proj", settings: projectRelease)
p += configBlock(
    "Debug", owner: "app",
    settings: localOnly ? appSettings.filter { $0.0 != "CODE_SIGN_ENTITLEMENTS" } : appSettings)
p += configBlock(
    "Release", owner: "app",
    settings: localOnly ? appSettings.filter { $0.0 != "CODE_SIGN_ENTITLEMENTS" } : appSettings)
if hasTests {
    p += configBlock("Debug", owner: "tests", settings: testSettings)
    p += configBlock("Release", owner: "tests", settings: testSettings)
}
p += "\n"
p += configList(oid("prjCfgList"), "proj")
p += configList(oid("tgtCfgList"), "app")
if hasTests { p += configList(oid("tests:cfgList"), "tests") }

p += "\t};\n\trootObject = \(pbxID) /* Project object */;\n}\n"

// MARK: Write project + shared scheme

let projDir = root.appendingPathComponent("MenteViva.xcodeproj")
/// Runs a filesystem step; on failure prints what failed instead of a trace.
func attempt(_ what: String, _ body: () throws -> Void) {
    do { try body() } catch { die("could not \(what): \(error.localizedDescription)") }
}
attempt("write project.pbxproj") {
    try FileManager.default.createDirectory(at: projDir, withIntermediateDirectories: true)
    try p.write(to: projDir.appendingPathComponent("project.pbxproj"), atomically: true, encoding: .utf8)
}

var testables = ""
func testable(_ id: String, bundle: String, name: String) -> String {
    "\t\t\t<TestableReference skipped=\"NO\">\n\t\t\t\t<BuildableReference BuildableIdentifier=\"primary\" BlueprintIdentifier=\"\(id)\" BuildableName=\"\(bundle)\" BlueprintName=\"\(name)\" ReferencedContainer=\"container:MenteViva.xcodeproj\"/>\n\t\t\t</TestableReference>\n"
}
if hasTests { testables += testable(testsTgtID, bundle: "MenteVivaTests.xctest", name: "MenteVivaTests") }

let appRef =
    "<BuildableReference BuildableIdentifier=\"primary\" BlueprintIdentifier=\"\(tgtID)\" BuildableName=\"MenteViva.app\" BlueprintName=\"MenteViva\" ReferencedContainer=\"container:MenteViva.xcodeproj\"/>"

let scheme = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Scheme LastUpgradeVersion="2700" version="1.7">
       <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
          <BuildActionEntries>
             <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
                \(appRef)
             </BuildActionEntry>
          </BuildActionEntries>
       </BuildAction>
       <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES" shouldAutocreateTestPlan="YES">
          <Testables>
    \(testables)      </Testables>
       </TestAction>
       <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
          <BuildableProductRunnable runnableDebuggingMode="0">
             \(appRef)
          </BuildableProductRunnable>
       </LaunchAction>
       <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
          <BuildableProductRunnable runnableDebuggingMode="0">
             \(appRef)
          </BuildableProductRunnable>
       </ProfileAction>
       <AnalyzeAction buildConfiguration="Debug"/>
       <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
    </Scheme>

    """

let schemeDir = projDir.appendingPathComponent("xcshareddata/xcschemes")
attempt("create the scheme folder") { try FileManager.default.createDirectory(at: schemeDir, withIntermediateDirectories: true) }
// Write the scheme only if absent: Xcode owns and reformats it from here on, and
// regenerating over it causes churn (formatting/LastUpgradeVersion) with no
// semantic value. Target IDs are deterministic, so a committed scheme stays valid.
let schemeFile = schemeDir.appendingPathComponent("MenteViva.xcscheme")
if !FileManager.default.fileExists(atPath: schemeFile.path) {
    attempt("write the scheme") { try scheme.write(to: schemeFile, atomically: true, encoding: .utf8) }
}

// Xcode expects the project's embedded workspace file. Without it the GUI
// reports a "file format integrity issue" even though xcodebuild parses fine.
// xcuserdata is left alone (per-user, gitignored); close Xcode before regenerating.
let wsDir = projDir.appendingPathComponent("project.xcworkspace")
attempt("create the workspace folder") { try FileManager.default.createDirectory(at: wsDir, withIntermediateDirectories: true) }
let workspaceData = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Workspace
       version = "1.0">
       <FileRef
          location = "self:">
       </FileRef>
    </Workspace>

    """
attempt("write the workspace file") {
    try workspaceData.write(to: wsDir.appendingPathComponent("contents.xcworkspacedata"), atomically: true, encoding: .utf8)
}

print(
    "Generated MenteViva.xcodeproj: \(appFiles.count) app files, \(testFiles.count) test files\(cloudKit ? " [cloudkit]" : " [local-only]")"
)
