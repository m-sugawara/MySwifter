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
    let assembler = Assembler([
        APIAssembly(),
        HelperAssembly(),
        ViewModelAssembly(),
        ViewControllerAssembly()
    ])

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)

        window?.rootViewController = assembler.resolver.resolve(MainViewController.self)!
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
        let callbackURL = URL(string: Consts.twitterCallbackAuthorize)!
        Swifter.handleOpenURL(url, callbackURL: callbackURL)

        return true
    }
}
