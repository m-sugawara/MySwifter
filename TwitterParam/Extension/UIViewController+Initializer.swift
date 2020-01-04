//
//  UIViewController+Initializer.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/01/01.
//  Copyright © 2020 sugawar. All rights reserved.
//

import UIKit

extension UIViewController {
    static func makeInstance() -> Self {
        let name = String(describing: self)
        let storyboard = UIStoryboard(name: name, bundle: nil)
        // swiftlint:disable force_cast
        return storyboard.instantiateInitialViewController() as! Self
    }
}
