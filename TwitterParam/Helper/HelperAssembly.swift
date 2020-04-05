//
//  HelperAssembly.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/04/05.
//  Copyright © 2020 sugawar. All rights reserved.
//

import Swinject

class HelperAssembly: Assembly {
    func assemble(container: Container) {
        // Helper
        container.register(DateHelper.self) { _ in DateHelper() }
        container.register(FileLoaderProtocol.self) { _ in FileLoader() }
        container.register(UserHelper.self) { _ in UserHelper() }
    }
}
