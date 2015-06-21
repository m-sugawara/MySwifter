//
//  UIViewController+TWPHelper.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/21.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

extension UIViewController {
    // MARK: - Alert
    func showAlertWithTitle(title: String?, message: String?, cancelButtonTitle: String? = "OK", cancelTappedAction: (()->Void)? = nil,  otherButtonTitles: [String]? = nil, otherButtonTappedActions: ((UIAlertAction!)->Void)!...) {
        if objc_getClass("UIAlertController") != nil {
            // use UIAlertController
            var alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: cancelButtonTitle!, style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                cancelTappedAction?()
                println("cancel")
            })
            alertController.addAction(cancelAction)
            
            // set other actions, if exists
            if let buttonTitles = otherButtonTitles {
                var i:Int = 0
                for otherButtonTitle: String in buttonTitles {
                    let otherButtonAction = UIAlertAction(title: otherButtonTitle, style: UIAlertActionStyle.Default, handler: otherButtonTappedActions[i])
                    alertController.addAction(otherButtonAction)
                    i++
                }
            }
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            // use UIAlertView
            var alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle)
            alertView.show()
        }
    }
}