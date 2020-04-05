//
//  ViewControllerAssembly.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/04/05.
//  Copyright © 2020 sugawar. All rights reserved.
//

import Swinject

class ViewControllerAssembly: Assembly {
    func assemble(container: Container) {
        container.register(LoginViewController.self) { resolver in
            let viewController = LoginViewController.makeInstance()
            viewController.model = resolver.resolve(LoginViewModelProtocol.self)!
            return viewController
        }
        container.register(MainViewController.self) { resolver in
            let viewController = MainViewController.makeInstance()
            viewController.model = resolver.resolve(MainViewModel.self)!
            viewController.container = container
            return viewController
        }
        container.register(TweetDetailViewController.self) { resolver in
            let viewController = TweetDetailViewController.makeInstance()
            viewController.model = resolver.resolve(TweetDetailViewModel.self)!
            return viewController
        }
        container.register(UserListViewController.self) { resolver in
            let viewController = UserListViewController.makeInstance()
            viewController.model = resolver.resolve(UserListViewModel.self)!
            viewController.container = container
            return viewController
        }
        container.register(UserInfoViewController.self) { resolver in
            let viewController = UserInfoViewController.makeInstance()
            viewController.model = resolver.resolve(UserInfoViewModel.self)!
            viewController.container = container
            return viewController
        }
    }
}
