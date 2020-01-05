//
//  UserHelper.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation
import Accounts

import SwifteriOS

class UserHelper {

    enum Keys: String, CaseIterable {
        case accountType
        case token
        case secret
        case screenName
        case userId
        case verifier

        func storedValue() -> String? {
            return UserDefaults.standard.string(forKey: rawValue)
        }
    }

    static func saveUserToken(data: Credential.OAuthAccessToken) {
        save(UserAccountType.oAuth.hashValue, forKey: .accountType)
        save(data.key, forKey: .token)
        save(data.secret, forKey: .secret)
        save(data.screenName, forKey: .screenName)
        save(data.userID, forKey: .userId)
        save(data.verifier, forKey: .verifier)
    }

    static func saveUserAccount(account: ACAccount) -> Bool {
        guard let userId = account.value(forKeyPath: "properties.user_id") as? String else { return false }
        save(UserAccountType.acAccount.hashValue, forKey: .accountType)
        save(nil, forKey: .token)
        save(nil, forKey: .secret)
        save(account.username, forKey: .screenName)
        save(userId, forKey: .userId)
        save(nil, forKey: .verifier)

        return true
    }

    static func removeUserToken() {
        Keys.allCases.forEach { key in
            remove(forKey: key)
        }
    }

    static func fetchUserToken() -> Credential? {
        guard let key = Keys.token.storedValue(),
            let secret = Keys.secret.storedValue() else {
                return nil
        }

        let accessToken = Credential.OAuthAccessToken(key: key, secret: secret)
        return Credential(accessToken: accessToken)
    }

    static func currentUserId() -> String? {
        return Keys.userId.storedValue()
    }

    static func isLoggedIn() -> Bool {
        return (Keys.userId.storedValue() != nil)
    }

    // MARK: - private

    private static func save(_ value: Any?, forKey key: Keys) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    private static func remove(forKey key: Keys) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
}
