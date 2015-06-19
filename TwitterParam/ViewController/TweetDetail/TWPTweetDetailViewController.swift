//
//  TWPTweetDetailViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/19.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPTweetDetailViewController: UIViewController {
    let model = TWPTweetDetailViewModel()
    
    var tempTweetID:String!
    var backButtonCommand:RACCommand!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tweetLabel: UILabel!
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.bindCommands()
        
        // TODO: Bad Solution
        self.model.tweetID = self.tempTweetID
        self.model.getTweetSignal()?.subscribeError({ (error) -> Void in
            println("error:\(error)")
        }, completed: { () -> Void in
            self.tweetLabel.text = self.model.tweet?.text
            self.userIconImageView.sd_setImageWithURL(self.model.tweet?.profileImageUrl,
                placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
                options: SDWebImageOptions.CacheMemoryOnly)
            
        })
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Binding
    func bindCommands() {
        self.backButton.rac_command = self.backButtonCommand
    }

}
