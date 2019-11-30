//
//  TWPTextFieldView.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/22.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import UITextFieldWithLimit

class TWPTextFieldView: UIView {

    @IBOutlet weak var textFieldWithLimit: UITextFieldWithLimit!
    @IBOutlet weak var tweetButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    // MARK: - Convenience Initializer
    class func view(
        withMaxLength maxLength: Int,
        delegate: UITextFieldWithLimitDelegate
    ) -> TWPTextFieldView {
        guard let view = Bundle.main.loadNibNamed(
            "TWPTextFieldView",
            owner: self,
            options: nil)?.first as? TWPTextFieldView else {
                fatalError()
        }
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.textFieldWithLimit.maxLength = maxLength as NSNumber
        view.textFieldWithLimit.delegate = delegate

        return view
    }

    // MARK: - Actions
    @IBAction func tweetButtonTapped(sender: AnyObject) {

    }

    @IBAction func cancelButtonTapped(sender: AnyObject) {

    }

}
