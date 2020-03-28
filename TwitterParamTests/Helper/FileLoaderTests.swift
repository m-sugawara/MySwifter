//
//  FileLoaderTests.swift
//  TwitterParamTests
//
//  Created by M_Sugawara on 2020/03/28.
//  Copyright © 2020 sugawar. All rights reserved.
//

import XCTest
import SwifteriOS

@testable import TwitterParam

class FileTests: XCTestCase {

    private var fileLoader: FileLoader!

    override func setUp() {
        fileLoader = FileLoader(bundle: Bundle(for: Self.self))
    }

    override func tearDown() {
        fileLoader = nil
    }

    func testLoadFile() {
        // swiftlint:disable force_try
        let data = try! fileLoader.loadFile(for: "Test", ofType: "json")
        XCTAssert(!data.isEmpty)
    }

    func testLoadFileInvalidPath() {
        do {
            _ = try fileLoader.loadFile(for: "InvalidPath", ofType: "json")
            XCTFail("found invalid file")
        } catch {
            let expected = FileLoaderError.invalidPath
            XCTAssertEqual(expected, error as? FileLoaderError)
        }
    }

    func testLoadJson() {
        // swiftlint:disable force_try
        let json: SampleJSON = try! fileLoader.loadJSON(fileName: "Test")

        let expectedID = "1234"
        let expectedName = "sample"

        XCTAssertEqual(expectedID, json.id)
        XCTAssertEqual(expectedName, json.name)
    }

}

struct SampleJSON: Codable {
    let id: String
    let name: String
}
