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
    
    var tempUserID: String!
    var backButtonCommand: RACCommand!
    
    var selectedTweetID: String!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if segue.identifier == "fromUserInfoToTweetDetail" {
            var tweetDetailViewController: TWPTweetDetailViewController = segue.destinationViewController as! TWPTweetDetailViewController
            
            tweetDetailViewController.tempTweetID = self.selectedTweetID
            
            tweetDetailViewController.backButtonCommand = RACCommand(signalBlock: { (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    // send completed for button status to acitive
                    subscriber.sendCompleted()
                    
                    return RACDisposable(block: { () -> Void in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
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
        
        if self.model.user.screenName != nil {
            self.screenNameLabel.text = self.model.user.screenNameWithAt!
        }
        else {
            self.screenNameLabel.text = "no data"
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
        
        cell.iconImageView.sd_setImageWithURL(tweet.user?.profileImageUrl,
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
        var selectedTweet: TWPTweet = self.model.tweets[indexPath.row] as! TWPTweet;
        self.selectedTweetID = selectedTweet.tweetID
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("fromUserInfoToTweetDetail", sender: nil)
    }
}
