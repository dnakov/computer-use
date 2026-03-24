import XCTest
@testable import ComputerUseSwift

final class DataTypeTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    // MARK: - ScreenshotResult

    func testScreenshotResultEncodesAllKeys() throws {
        let result = ScreenshotResult(
            base64: "data:image/jpeg;base64,abc",
            width: 1920,
            height: 1080,
            displayWidth: 2560,
            displayHeight: 1440,
            displayId: 1,
            originX: 0,
            originY: 0,
            captureError: nil
        )
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let keys = Set(dict.keys)
        let expected: Set<String> = [
            "base64", "width", "height", "displayWidth", "displayHeight",
            "displayId", "originX", "originY", "captureError"
        ]
        XCTAssertEqual(keys, expected)
    }

    func testScreenshotResultCaptureErrorNull() throws {
        let result = ScreenshotResult(
            base64: "data:image/jpeg;base64,abc",
            width: 100,
            height: 100,
            displayWidth: 200,
            displayHeight: 200,
            displayId: 1,
            originX: 0,
            originY: 0,
            captureError: nil
        )
        let data = try encoder.encode(result)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("\"captureError\":null"))
    }

    func testScreenshotResultCaptureErrorPresent() throws {
        let result = ScreenshotResult(
            base64: "data:image/jpeg;base64,abc",
            width: 100,
            height: 100,
            displayWidth: 200,
            displayHeight: 200,
            displayId: 1,
            originX: 0,
            originY: 0,
            captureError: "some error"
        )
        let data = try encoder.encode(result)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("\"captureError\":\"some error\""))
    }

    func testScreenshotResultRoundTrip() throws {
        let original = ScreenshotResult(
            base64: "data:image/jpeg;base64,test123",
            width: 1920,
            height: 1080,
            displayWidth: 2560,
            displayHeight: 1440,
            displayId: 42,
            originX: 100,
            originY: 200,
            captureError: "test error"
        )
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(ScreenshotResult.self, from: data)
        XCTAssertEqual(decoded.base64, original.base64)
        XCTAssertEqual(decoded.width, original.width)
        XCTAssertEqual(decoded.height, original.height)
        XCTAssertEqual(decoded.displayWidth, original.displayWidth)
        XCTAssertEqual(decoded.displayHeight, original.displayHeight)
        XCTAssertEqual(decoded.displayId, original.displayId)
        XCTAssertEqual(decoded.originX, original.originX)
        XCTAssertEqual(decoded.originY, original.originY)
        XCTAssertEqual(decoded.captureError, original.captureError)
    }

    // MARK: - PrepareDisplayResult

    func testPrepareDisplayResultWithActivated() throws {
        let result = PrepareDisplayResult(
            hidden: ["com.example.app1", "com.example.app2"],
            activated: "com.example.app1"
        )
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["hidden"] as? [String], ["com.example.app1", "com.example.app2"])
        XCTAssertEqual(dict["activated"] as? String, "com.example.app1")
    }

    func testPrepareDisplayResultWithoutActivated() throws {
        let result = PrepareDisplayResult(hidden: [], activated: nil)
        let data = try encoder.encode(result)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("\"activated\":null"))
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["hidden"] as? [String], [])
    }

    func testPrepareDisplayResultKeys() throws {
        let result = PrepareDisplayResult(hidden: [], activated: nil)
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(Set(dict.keys), Set(["hidden", "activated"]))
    }

    // MARK: - InstalledAppJson

    func testInstalledAppJsonEncoding() throws {
        let app = InstalledApp(
            bundleId: "com.example.app",
            displayName: "Example App",
            path: "/Applications/Example.app"
        )
        let json = InstalledAppJson(from: app)
        let data = try encoder.encode(json)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["bundleId"] as? String, "com.example.app")
        XCTAssertEqual(dict["displayName"] as? String, "Example App")
        XCTAssertEqual(dict["path"] as? String, "/Applications/Example.app")
    }

    func testInstalledAppJsonKeys() throws {
        let app = InstalledApp(
            bundleId: "com.example",
            displayName: "Test",
            path: "/test"
        )
        let json = InstalledAppJson(from: app)
        let data = try encoder.encode(json)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(Set(dict.keys), Set(["bundleId", "displayName", "path"]))
    }

    func testInstalledAppJsonRoundTrip() throws {
        let app = InstalledApp(
            bundleId: "com.example.roundtrip",
            displayName: "Round Trip App",
            path: "/Applications/RoundTrip.app"
        )
        let original = InstalledAppJson(from: app)
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(InstalledAppJson.self, from: data)
        XCTAssertEqual(decoded.bundleId, original.bundleId)
        XCTAssertEqual(decoded.displayName, original.displayName)
        XCTAssertEqual(decoded.path, original.path)
    }

    // MARK: - DisplayInfo

    func testDisplayInfoWithIsPrimary() throws {
        let info = DisplayInfo(
            displayId: 1,
            width: 2560,
            height: 1440,
            scaleFactor: 2.0,
            originX: 0,
            originY: 0,
            isPrimary: true
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["isPrimary"] as? Bool, true)
        XCTAssertEqual(dict["displayId"] as? Int, 1)
        XCTAssertEqual(dict["width"] as? Int, 2560)
        XCTAssertEqual(dict["height"] as? Int, 1440)
        XCTAssertEqual(dict["scaleFactor"] as? Double, 2.0)
        XCTAssertEqual(dict["originX"] as? Int, 0)
        XCTAssertEqual(dict["originY"] as? Int, 0)
    }

    func testDisplayInfoWithNilIsPrimary() throws {
        let info = DisplayInfo(
            displayId: 2,
            width: 1920,
            height: 1080,
            scaleFactor: 1.0,
            originX: 2560,
            originY: 0,
            isPrimary: nil
        )
        let data = try encoder.encode(info)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("\"isPrimary\":null"))
    }

    func testDisplayInfoKeys() throws {
        let info = DisplayInfo(
            displayId: 1,
            width: 100,
            height: 100,
            scaleFactor: 1.0,
            originX: 0,
            originY: 0,
            isPrimary: true
        )
        let data = try encoder.encode(info)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let expected: Set<String> = [
            "displayId", "width", "height", "scaleFactor",
            "originX", "originY", "isPrimary"
        ]
        XCTAssertEqual(Set(dict.keys), expected)
    }

    // MARK: - FindWindowDisplaysResult

    func testFindWindowDisplaysResultEncoding() throws {
        let result = FindWindowDisplaysResult(displayIds: [1, 2, 3])
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["displayIds"] as? [Int], [1, 2, 3])
    }

    func testFindWindowDisplaysResultEmptyArray() throws {
        let result = FindWindowDisplaysResult(displayIds: [])
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(dict["displayIds"] as? [Int], [])
    }

    func testFindWindowDisplaysResultKeys() throws {
        let result = FindWindowDisplaysResult(displayIds: [1])
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(Set(dict.keys), Set(["displayIds"]))
    }

    // MARK: - ResolvePrepareCaptureResult

    func testResolvePrepareCaptureResultEncoding() throws {
        let screenshot = ScreenshotResult(
            base64: "data:image/jpeg;base64,abc",
            width: 800,
            height: 600,
            displayWidth: 1920,
            displayHeight: 1080,
            displayId: 1,
            originX: 0,
            originY: 0,
            captureError: nil
        )
        let result = ResolvePrepareCaptureResult(
            screenshot: screenshot,
            hidden: ["com.example.app"],
            activated: "com.example.app",
            displayId: 1
        )
        let data = try encoder.encode(result)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertNotNil(dict["screenshot"])
        XCTAssertEqual(dict["hidden"] as? [String], ["com.example.app"])
        XCTAssertEqual(dict["activated"] as? String, "com.example.app")
        XCTAssertEqual(dict["displayId"] as? Int, 1)
    }

    func testResolvePrepareCaptureResultNullScreenshot() throws {
        let result = ResolvePrepareCaptureResult(
            screenshot: nil,
            hidden: [],
            activated: nil,
            displayId: 1
        )
        let data = try encoder.encode(result)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("\"screenshot\":null"))
        XCTAssertTrue(json.contains("\"activated\":null"))
    }
}
