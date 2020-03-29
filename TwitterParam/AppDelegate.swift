//
//  AppDelegate.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS
import Swinject

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let container = Container() { container in
        // Helper
        container.register(DateHelper.self) { _ in DateHelper() }
        container.register(FileLoaderProtocol.self) { _ in FileLoader() }
        container.register(UserHelper.self) { _ in UserHelper() }

        // API
        container.register(TwitterAPI.self) { resolver in
            let fileLoader = resolver.resolve(FileLoaderProtocol.self)!
            // swiftlint:disable force_try
            let secrets: TwitterSecrets = try! fileLoader.loadPlist(fileName: "TwitterSecrets")
            let twitterAPI = TwitterAPI(secrets: secrets)
            twitterAPI.userHelper = resolver.resolve(UserHelper.self)!
            return twitterAPI
        }

        // ViewModel
        container.register(LoginViewModel.self) { resolver in
            let model = LoginViewModel()
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            return model
        }
        container.register(MainViewModel.self) { resolver in
            let model = MainViewModel()
            model.userHelper = resolver.resolve(UserHelper.self)!
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            return model
        }
        container.register(TweetDetailViewModel.self) { resolver in
            let model = TweetDetailViewModel()
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            return model
        }
        container.register(UserListViewModel.self) { resolver in
            let model = UserListViewModel()
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            return model
        }
        container.register(UserInfoViewModel.self) { resolver in
            let model = UserInfoViewModel()
            model.twitterAPI = resolver.resolve(TwitterAPI.self)!
            model.userHelper = resolver.resolve(UserHelper.self)!
            return model
        }

        // ViewController
        container.register(LoginViewController.self) { resolver in
            let viewController = LoginViewController.makeInstance()
            viewController.model = resolver.resolve(LoginViewModel.self)!
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

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)

        window?.rootViewController = container.resolve(MainViewController.self)!
        window?.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    // swiftlint:disable identifier_name
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        Swifter.handleOpenURL(url, callbackURL: url)

        return true
    }
}
