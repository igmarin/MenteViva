import XCTest

@testable import MenteViva

/// #364: App Store Connect rejects uploads whose required-reason API use is not declared
/// (ITMS-91053). The manifest must ship in the app bundle and agree with "Data Not Collected".
final class PrivacyManifestTests: XCTestCase {
    func testGivenTheAppBundleWhenReadingThePrivacyManifestThenUserDefaultsAndFileTimestampReasonsAreDeclared()
        throws
    {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"),
            "PrivacyInfo.xcprivacy must be at the root of the app bundle")
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])

        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((plist["NSPrivacyTrackingDomains"] as? [Any])?.count, 0)
        XCTAssertEqual((plist["NSPrivacyCollectedDataTypes"] as? [Any])?.count, 0)

        let apis = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        var reasons: [String: [String]] = [:]
        for api in apis {
            let category = try XCTUnwrap(api["NSPrivacyAccessedAPIType"] as? String)
            reasons[category] = api["NSPrivacyAccessedAPITypeReasons"] as? [String]
        }
        XCTAssertEqual(reasons.count, 2)
        XCTAssertEqual(reasons["NSPrivacyAccessedAPICategoryUserDefaults"], ["CA92.1"])
        XCTAssertEqual(reasons["NSPrivacyAccessedAPICategoryFileTimestamp"], ["C617.1"])
    }
}
