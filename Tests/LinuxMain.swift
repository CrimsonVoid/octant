import XCTest

import octantTests

var tests = [XCTestCaseEntry]()
tests += octantTests.allTests()
XCTMain(tests)
