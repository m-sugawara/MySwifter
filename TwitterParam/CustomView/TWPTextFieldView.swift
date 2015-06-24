//
//  TWPTextFieldView.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/22.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPTextFieldView: UIView {
    
    @IBOutlet weak var textFieldWithLimit: UITextFieldWithLimit!
    @IBOutlet weak var tweetButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    // MARK: - Designated Initializer
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Convenience Initializer
    class func viewWithMaxLength(maxLength: Int, delegate: UITextFieldWithLimitDelegate) -> TWPTextFieldView {
        let view: TWPTextFieldView = NSBundle.mainBundle().loadNibNamed("TWPTextFieldView", owner: self, options: nil).first as! TWPTextFieldView
        view.setTranslatesAutoresizingMaskIntoConstraints(true)
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth|UIViewAutoresizing.FlexibleHeight
        
        view.textFieldWithLimit.maxLength = maxLength
        view.textFieldWithLimit.delegate = delegate
        
        return view
    }

    // MARK: - Actions
    @IBAction func tweetButtonTapped(sender: AnyObject) {
        
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        
    }

}
