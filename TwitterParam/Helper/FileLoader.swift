//
//  FileLoader.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/03/14.
//  Copyright © 2020 sugawar. All rights reserved.
//

import Foundation

enum FileLoaderError: Error {
    case invalidPath
}

protocol FileLoaderProtocol {
    func loadFile(for resource: String, ofType type: String) throws -> Data
    func loadJSON<T: Decodable>(fileName: String, decoder: JSONDecoder) throws -> T
}

class FileLoader: FileLoaderProtocol {

    private let bundle: Bundle

    convenience init() {
        self.init(bundle: .main)
    }

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func loadFile(for resource: String, ofType type: String) throws -> Data {

        guard let path = bundle.path(forResource: resource, ofType: type) else {
            throw FileLoaderError.invalidPath
        }
        do {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return data
        } catch {
            throw error
        }
    }

    func loadJSON<T: Decodable>(fileName: String, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let data = try loadFile(for: fileName, ofType: "json")
        let jsonData = try decoder.decode(T.self, from: data)
        return jsonData
    }
}
