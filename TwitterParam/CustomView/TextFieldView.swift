//
//  TextFieldView.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/22.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import UITextFieldWithLimit

protocol TextFieldViewDelegate: class {
    func textFieldViewDidTapTweetButton()
    func textFieldViewDidTapCancelButton()
}

class TextFieldView: UIView {

    weak var delegate: TextFieldViewDelegate?

    @IBOutlet weak var textFieldWithLimit: UITextFieldWithLimit!
    @IBOutlet weak var tweetButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    var maxLength: Int {
        get {
            return textFieldWithLimit.maxLength.intValue
        }
        set {
            textFieldWithLimit.maxLength = newValue as NSNumber
            textFieldWithLimit.limitLabel.text = String(newValue)
        }
    }

    // MARK: - Convenience Initializer
    static func view() -> TextFieldView {
        guard let view = Bundle.main.loadNibNamed(
            "TextFieldView",
            owner: self,
            options: nil)?.first as? TextFieldView else {
                fatalError()
        }
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.alpha = 0.0
        view.maxLength = 140

        return view
    }

    // MARK: - Public functions
    func activate(withText text: String) {
        alpha = 0.01
        textFieldWithLimit.becomeFirstResponder()
        textFieldWithLimit.text = text
    }

    func deactivate() {
        alpha = 0.0
        textFieldWithLimit.resignFirstResponder()
    }

    // MARK: - Actions
    @IBAction func tweetButtonTapped(sender: AnyObject) {
        delegate?.textFieldViewDidTapTweetButton()
    }

    @IBAction func cancelButtonTapped(sender: AnyObject) {
        delegate?.textFieldViewDidTapCancelButton()
    }
}
