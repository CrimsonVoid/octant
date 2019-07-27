import XCTest
@testable import octant

final class octantTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(octant().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
