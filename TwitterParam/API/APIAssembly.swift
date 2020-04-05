//
//  APIAssembly.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/04/05.
//  Copyright © 2020 sugawar. All rights reserved.
//

import Swinject

class APIAssembly: Assembly {
    func assemble(container: Container) {
        // API
        container.register(TwitterAPI.self) { resolver in
            let fileLoader = resolver.resolve(FileLoaderProtocol.self)!
            // swiftlint:disable force_try
            let secrets: TwitterSecrets = try! fileLoader.loadPlist(fileName: "TwitterSecrets")
            let twitterAPI = TwitterAPI(secrets: secrets)
            twitterAPI.userHelper = resolver.resolve(UserHelper.self)!
            return twitterAPI
        }
    }
}
