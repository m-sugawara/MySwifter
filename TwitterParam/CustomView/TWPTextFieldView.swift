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
    class func viewWithMaxLength(maxLength: Int, delegate: UITextFieldWithLimitDelegate) -> TWPTextFieldView {
        let view: TWPTextFieldView = Bundle.main.loadNibNamed("TWPTextFieldView", owner: self, options: nil)?.first as! TWPTextFieldView
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        
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
