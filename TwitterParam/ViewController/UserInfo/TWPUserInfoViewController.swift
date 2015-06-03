//
//  TWPUserInfoViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPUserInfoViewController: UIViewController {
    let model = TWPUserInfoViewModel()
    
    var tempUserID:String!
    var backButtonCommand:RACCommand!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var userTweetsTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        
        // TODO: bad solution
        self.model.userID = self.tempUserID
        
        super.viewDidLoad()
        
        self.bindCommands()
        
        // get user info
        self.model.getUserInfoSignal().subscribeNext({ (user) -> Void in
            println("viewController.user:\(user)")
        }, error: { (error) -> Void in
            println("viewController.error:\(error)")
        }) { () -> Void in
            self.setUserProfile()
            println("viewController's get userinfo completed")
        }
    }
    
    // MARK: - Binding
    func bindCommands() {
        self.backButton.rac_command = self.backButtonCommand
    }
    
    // MARK: - Private Methods
    func setUserProfile() {
        self.userNameLabel.text = self.model.user.name
        
        if self.model.user.screen_name != nil {
            self.userIDLabel.text = "@" + self.model.user.screen_name!
        }
        else {
            self.userIDLabel.text = "no data"
        }
    }
}
