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
    func showAlert(with title: String?, message: String?,
                   cancelButtonTitle: String = "OK",
                   cancelTappedAction: (()->Void)? = nil,
                   otherButtonTitles: [String]? = nil,
                   otherButtonTappedActions: ((UIAlertAction?)->Void)?...) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { (action) -> Void in
            cancelTappedAction?()
        })
        alertController.addAction(cancelAction)

        // set other actions, if exists
        if let otherButtonTitles = otherButtonTitles {
            for i in 0..<otherButtonTitles.count {
                let otherButtonTitle = otherButtonTitles[i]
                let otherButtonAction = UIAlertAction(title: otherButtonTitle, style: .default, handler: otherButtonTappedActions[i])
                alertController.addAction(otherButtonAction)
            }
        }

        present(alertController, animated: true, completion: nil)
    }
}
