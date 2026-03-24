import XCTest
@testable import ComputerUseSwift

final class NewModelTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    // MARK: - FrontmostAppInfo

    func testFrontmostAppInfoEncoding() throws {
        let info = FrontmostAppInfo(
            appName: "Safari",
            bundleId: "com.apple.Safari",
            appIconBase64: "data:image/png;base64,abc"
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["appName"] as? String, "Safari")
        XCTAssertEqual(dict["bundleId"] as? String, "com.apple.Safari")
        XCTAssertEqual(dict["appIconBase64"] as? String, "data:image/png;base64,abc")
    }

    func testFrontmostAppInfoKeys() throws {
        let info = FrontmostAppInfo(
            appName: "Test",
            bundleId: "com.test",
            appIconBase64: "icon"
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(Set(dict.keys), Set(["appName", "bundleId", "appIconBase64"]))
    }

    func testFrontmostAppInfoRoundTrip() throws {
        let original = FrontmostAppInfo(
            appName: "Finder",
            bundleId: "com.apple.finder",
            appIconBase64: "data:image/png;base64,xyz"
        )
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(FrontmostAppInfo.self, from: data)
        XCTAssertEqual(decoded.appName, original.appName)
        XCTAssertEqual(decoded.bundleId, original.bundleId)
        XCTAssertEqual(decoded.appIconBase64, original.appIconBase64)
    }

    // MARK: - AppInfoForFile

    func testAppInfoForFileEncoding() throws {
        let info = AppInfoForFile(
            appName: "TextEdit",
            appIconBase64: "data:image/png;base64,def"
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["appName"] as? String, "TextEdit")
        XCTAssertEqual(dict["appIconBase64"] as? String, "data:image/png;base64,def")
    }

    func testAppInfoForFileKeys() throws {
        let info = AppInfoForFile(appName: "Test", appIconBase64: "icon")
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(Set(dict.keys), Set(["appName", "appIconBase64"]))
    }

    func testAppInfoForFileRoundTrip() throws {
        let original = AppInfoForFile(
            appName: "Preview",
            appIconBase64: "data:image/png;base64,ghi"
        )
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(AppInfoForFile.self, from: data)
        XCTAssertEqual(decoded.appName, original.appName)
        XCTAssertEqual(decoded.appIconBase64, original.appIconBase64)
    }

    // MARK: - MouseLocation

    func testMouseLocationEncoding() throws {
        let loc = MouseLocation(x: 100, y: 200)
        let data = try encoder.encode(loc)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["x"] as? Int, 100)
        XCTAssertEqual(dict["y"] as? Int, 200)
    }

    func testMouseLocationKeys() throws {
        let loc = MouseLocation(x: 0, y: 0)
        let data = try encoder.encode(loc)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(Set(dict.keys), Set(["x", "y"]))
    }

    func testMouseLocationRoundTrip() throws {
        let original = MouseLocation(x: 1920, y: 1080)
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(MouseLocation.self, from: data)
        XCTAssertEqual(decoded.x, original.x)
        XCTAssertEqual(decoded.y, original.y)
    }

    func testMouseLocationNegativeCoordinates() throws {
        let loc = MouseLocation(x: -50, y: -100)
        let data = try encoder.encode(loc)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["x"] as? Int, -50)
        XCTAssertEqual(dict["y"] as? Int, -100)
    }

    // MARK: - AuthResult

    func testAuthResultEncodingWithValues() throws {
        let result = AuthResult(callbackUrl: "myapp://callback?code=abc", error: nil)
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["callbackUrl"] as? String, "myapp://callback?code=abc")
        XCTAssertTrue(dict["error"] is NSNull)
    }

    func testAuthResultEncodingWithError() throws {
        let result = AuthResult(callbackUrl: nil, error: "Authentication cancelled")
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertTrue(dict["callbackUrl"] is NSNull)
        XCTAssertEqual(dict["error"] as? String, "Authentication cancelled")
    }

    func testAuthResultEncodingBothNull() throws {
        let result = AuthResult(callbackUrl: nil, error: nil)
        let data = try encoder.encode(result)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("\"callbackUrl\":null"))
        XCTAssertTrue(json.contains("\"error\":null"))
    }

    func testAuthResultKeys() throws {
        let result = AuthResult(callbackUrl: nil, error: nil)
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(Set(dict.keys), Set(["callbackUrl", "error"]))
    }

    func testAuthResultRoundTrip() throws {
        let original = AuthResult(callbackUrl: "myapp://done", error: nil)
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(AuthResult.self, from: data)
        XCTAssertEqual(decoded.callbackUrl, original.callbackUrl)
        XCTAssertEqual(decoded.error, original.error)
    }
}
