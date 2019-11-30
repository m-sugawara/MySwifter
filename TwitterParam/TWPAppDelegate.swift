//
//  AppDelegate.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS

@UIApplicationMain
class TWPAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private func application(
        application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?
    ) -> Bool {
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

    private func application(
        application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?
    ) -> Bool {
        Swifter.handleOpenURL(url as URL, callbackURL: url as URL)

        return true
    }

}
