#!/usr/bin/env swift
// Generates MenteViva.xcodeproj from the files on disk. No external deps.
// Re-run after adding source files: swift tools/generate_project.swift
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appDir = root.appendingPathComponent("MenteViva")

var swiftFiles: [String] = []
let enumerator = FileManager.default.enumerator(at: appDir, includingPropertiesForKeys: nil)!
for case let url as URL in enumerator where url.pathExtension == "swift" {
    swiftFiles.append(url.path.replacingOccurrences(of: appDir.path + "/", with: ""))
}
swiftFiles.sort()

// Stable, deterministic IDs: FNV-1a hash → 24 hex chars.
func oid(_ s: String) -> String {
    var h: UInt64 = 0xcbf29ce484222325
    for b in s.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
    return String(format: "%016llX%08X", h, UInt32(s.count))
}

let appID = oid("MenteViva.app"), grpID = oid("group"), srcsID = oid("Sources")
let resID = oid("Resources"), fwID = oid("Frameworks"), pbxID = oid("proj")
let tgtID = oid("target"), plistID = oid("Info.plist"), catID = oid("xcstrings")
let catBuildID = oid("xcstrings.build")

var fileRefs = "", buildFiles = "", children = "", phaseFiles = ""
for f in swiftFiles {
    let ref = oid(f), bld = oid(f + ".build"), name = URL(fileURLWithPath: f).lastPathComponent
    fileRefs += "\t\t\(ref) /* \(name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \(f); sourceTree = \"<group>\"; };\n"
    buildFiles += "\t\t\(bld) /* \(name) in Sources */ = {isa = PBXBuildFile; fileRef = \(ref); };\n"
    children += "\t\t\t\t\(ref) /* \(name) */,\n"
    phaseFiles += "\t\t\t\t\(bld) /* \(name) in Sources */,\n"
}

var p = """
// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = { };
\tobjectVersion = 56;
\tobjects = {

"""
p += buildFiles + "\n" + fileRefs
p += "\t\t\(appID) /* MenteViva.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MenteViva.app; sourceTree = BUILT_PRODUCTS_DIR; };\n"
p += "\t\t\(plistID) /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; };\n"
p += "\t\t\(catID) /* Localizable.xcstrings */ = {isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = Localizable.xcstrings; sourceTree = \"<group>\"; };\n\n"
p += "\t\t\(catBuildID) /* Localizable.xcstrings in Resources */ = {isa = PBXBuildFile; fileRef = \(catID); };\n\n"
p += "\t\t\(grpID) /* MenteViva */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\(children)\t\t\t\t\(plistID) /* Info.plist */,\n\t\t\t\t\(catID) /* Localizable.xcstrings */,\n\t\t\t);\n\t\t\tpath = MenteViva;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n\n"
p += "\t\t\(tgtID) /* MenteViva */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = \(oid("tgtCfgList")) /* Build configuration list for PBXNativeTarget \"MenteViva\" */;\n\t\t\tbuildPhases = ( \(srcsID) /* Sources */, \(fwID) /* Frameworks */, \(resID) /* Resources */ );\n\t\t\tbuildRules = ( );\n\t\t\tdependencies = ( );\n\t\t\tname = MenteViva;\n\t\t\tproductName = MenteViva;\n\t\t\tproductReference = \(appID);\n\t\t\tproductType = \"com.apple.product-type.application\";\n\t\t};\n\n"
p += "\t\t\(pbxID) /* Project object */ = {\n\t\t\tisa = PBXProject;\n\t\t\tattributes = { BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; };\n\t\t\tbuildConfigurationList = \(oid("prjCfgList")) /* Build configuration list for PBXProject \"MenteViva\" */;\n\t\t\tcompatibilityVersion = \"Xcode 14.0\";\n\t\t\tdevelopmentRegion = en;\n\t\t\thasScannedForEncodings = 0;\n\t\t\tknownRegions = ( en, Base, es );\n\t\t\tmainGroup = \(grpID);\n\t\t\tproductRefGroup = \(grpID);\n\t\t\tprojectDirPath = \"\";\n\t\t\tprojectRoot = \"\";\n\t\t\ttargets = ( \(tgtID) /* MenteViva */ );\n\t\t};\n\n"
p += "\t\t\(resID) /* Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = ( \(catBuildID) /* Localizable.xcstrings in Resources */ );\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\n"
p += "\t\t\(fwID) /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = ( );\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\n"
p += "\t\t\(srcsID) /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\(phaseFiles)\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\n"
func configBlock(_ name: String, _ opt: String, _ target: Bool) -> String {
    let cfgID = oid(name + (target ? "T" : "P"))
    var s = "\t\t" + cfgID + " /* " + name + " */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n\t\t\t\tSDKROOT = iphoneos;\n\t\t\t\tSWIFT_VERSION = 5.0;\n\t\t\t\tENABLE_PREVIEWS = YES;\n\t\t\t\t" + opt + "\n"
    if target {
        s += """
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = MenteViva/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Mente Viva";
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 0.1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.igmarin.MenteViva;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";

"""
    }
    s += "\t\t\t};\n\t\t\tname = " + name + ";\n\t\t};\n\n"
    return s
}

func configList(_ listID: String, _ target: Bool) -> String {
    let suffix = target ? "T" : "P"
    return "\t\t" + listID + " = { isa = XCConfigurationList; buildConfigurations = ( " + oid("Debug" + suffix) + ", " + oid("Release" + suffix) + " ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };\n\n"
}

p += configBlock("Debug", "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";", false)
p += configBlock("Release", "SWIFT_OPTIMIZATION_LEVEL = \"-O\";", false)
p += configBlock("Debug", "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";", true)
p += configBlock("Release", "SWIFT_OPTIMIZATION_LEVEL = \"-O\";", true)
p += configList(oid("prjCfgList"), false)
p += configList(oid("tgtCfgList"), true)
p += "\t};\n\trootObject = " + pbxID + " /* Project object */;\n}\n"

let projDir = root.appendingPathComponent("MenteViva.xcodeproj")
try FileManager.default.createDirectory(at: projDir, withIntermediateDirectories: true)
try p.write(to: projDir.appendingPathComponent("project.pbxproj"), atomically: true, encoding: .utf8)
print("Generated MenteViva.xcodeproj with \(swiftFiles.count) source files")
