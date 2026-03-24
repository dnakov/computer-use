import XCTest
@testable import ComputerUseSwift

final class PlistValueTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    // MARK: - Encoding

    func testStringEncodesAsJsonString() throws {
        let value = PlistValue.string("hello")
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "\"hello\"")
    }

    func testBoolTrueEncodesAsJsonBoolean() throws {
        let value = PlistValue.bool(true)
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "true")
    }

    func testBoolFalseEncodesAsJsonBoolean() throws {
        let value = PlistValue.bool(false)
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "false")
    }

    func testIntegerEncodesAsJsonNumber() throws {
        let value = PlistValue.integer(42)
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "42")
    }

    func testNegativeIntegerEncodesAsJsonNumber() throws {
        let value = PlistValue.integer(-7)
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "-7")
    }

    func testFloatEncodesAsJsonFloat() throws {
        let value = PlistValue.float(3.14)
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("3.14"))
    }

    func testZeroIntegerEncodes() throws {
        let value = PlistValue.integer(0)
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "0")
    }

    // MARK: - Round-trip

    func testStringRoundTrip() throws {
        let original = PlistValue.string("test")
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(PlistValue.self, from: data)
        if case .string(let v) = decoded {
            XCTAssertEqual(v, "test")
        } else {
            XCTFail("Expected .string, got \(decoded)")
        }
    }

    func testBoolRoundTrip() throws {
        let original = PlistValue.bool(true)
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(PlistValue.self, from: data)
        if case .bool(let v) = decoded {
            XCTAssertEqual(v, true)
        } else {
            XCTFail("Expected .bool, got \(decoded)")
        }
    }

    func testIntegerRoundTrip() throws {
        let original = PlistValue.integer(99)
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(PlistValue.self, from: data)
        if case .integer(let v) = decoded {
            XCTAssertEqual(v, 99)
        } else {
            XCTFail("Expected .integer, got \(decoded)")
        }
    }

    func testFloatRoundTrip() throws {
        let original = PlistValue.float(2.718)
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(PlistValue.self, from: data)
        if case .float(let v) = decoded {
            XCTAssertEqual(v, 2.718, accuracy: 0.001)
        } else {
            XCTFail("Expected .float, got \(decoded)")
        }
    }

    func testEmptyStringRoundTrip() throws {
        let original = PlistValue.string("")
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(PlistValue.self, from: data)
        if case .string(let v) = decoded {
            XCTAssertEqual(v, "")
        } else {
            XCTFail("Expected .string, got \(decoded)")
        }
    }

    func testBoolFalseRoundTrip() throws {
        let original = PlistValue.bool(false)
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(PlistValue.self, from: data)
        if case .bool(let v) = decoded {
            XCTAssertEqual(v, false)
        } else {
            XCTFail("Expected .bool, got \(decoded)")
        }
    }
}
