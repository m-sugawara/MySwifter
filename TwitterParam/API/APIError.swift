//
//  APIError.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/01/04.
//  Copyright © 2020 sugawar. All rights reserved.
//

import Foundation

enum APIError: Int, Error {
    case noTwitterAccount = -100
    case notGrantedACAccount = -101
    case failedToParseJSON = -102
    case failedToGetUserId = -103
    case generalError = -999

    var errorCode: Int {
        return rawValue
    }

    var localizedDescription: String {
        switch self {
        case .noTwitterAccount:
            return "There is no configured Twitter account"
        case .notGrantedACAccount:
            return "granted account not found"
        case .failedToParseJSON:
            return "failed to parse JSON Data"
        case .failedToGetUserId:
            return "failed to get userId"
        case .generalError:
            return "sorry, something went wrong"
        }
    }
}
