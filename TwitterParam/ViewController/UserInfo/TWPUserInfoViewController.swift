//
//  TWPUserInfoViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

let kTWPUserInfoTableViewCellIdentifier = "UserInfoTableViewCell";

class TWPUserInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let model = TWPUserInfoViewModel()
    
    var tempUserID:String!
    var backButtonCommand:RACCommand!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var userTweetsTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
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
            
            self.model.getUserTimelineSignal().subscribeError({ (error) -> Void in
                println("getUserTimeline.error:\(error)")
            }, completed: { () -> Void in
                self.tableView.reloadData()
                println("getUserTimeline completed!")
            })
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
        
        self.userIconImageView.sd_setImageWithURL(self.model.user.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: SDWebImageOptions.CacheMemoryOnly)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.model.tweets.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:TWPUserInfoViewControllerTableViewCell! = tableView.dequeueReusableCellWithIdentifier(kTWPUserInfoTableViewCellIdentifier) as? TWPUserInfoViewControllerTableViewCell
        
        // create Tweet Object
        var tweet:TWPTweet = self.model.tweets[indexPath.row] as! TWPTweet
        
        cell.iconImageView.sd_setImageWithURL(tweet.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: SDWebImageOptions.CacheMemoryOnly)
        cell.tweetTextLabel.text = tweet.text
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
