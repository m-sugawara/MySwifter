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
    func showAlertWithTitle(title: String?, message: String?, cancelButtonTitle: String? = "OK", cancelTappedAction: (()->Void)? = nil) {
        if objc_getClass("UIAlertController") != nil {
            // use UIAlertController
            var alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: cancelButtonTitle!, style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                cancelTappedAction?()
                println("cancel")
            })
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            // use UIAlertView
            var alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelButtonTitle)
            alertView.show()
        }
    }
}