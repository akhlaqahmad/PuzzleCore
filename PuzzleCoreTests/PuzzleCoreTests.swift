//
//  PuzzleCoreTests.swift
//  PuzzleCoreTests
//
//  Created by Akhlaq Ahmad on 23/01/2026.
//

import XCTest
@testable import PuzzleCore

final class PuzzleCoreTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGameViewControllerInitialization() throws {
        let vc = GameViewController()
        XCTAssertNotNil(vc)
        // We can't easily load view in unit test without a window/scene usually,
        // but we can check if it initializes.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
