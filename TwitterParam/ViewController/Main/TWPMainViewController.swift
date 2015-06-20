//
//  MainViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

let kTWPMainTableViewCellIdentifier = "MainTableViewCell";

enum TWPMainTableViewButtonType: Int {
    case reply = 1
    case retweet
    case favorite
}

class TWPMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {
    let model = TWPMainViewModel()
    var userID:String!
    var selectedTweetID:String!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var oauthButton: UIButton!
    @IBOutlet weak var accountButton: UIButton!
    @IBOutlet weak var feedUpdateButton: UIButton!
    
    // MARK: - Disignated Initializer
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.bindCommands();
        
        // bind tableView Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        // UserInfoViewController
        if segue.identifier == "fromMainToUserInfo" {
            var userInfoViewController:TWPUserInfoViewController = segue.destinationViewController as! TWPUserInfoViewController
            
            // TODO: bad solution
            let user = TWPUserHelper.fetchUserQData()
            userInfoViewController.tempUserID = user["userID"] as? String
            
            // bind Next ViewController's Commands
            userInfoViewController.backButtonCommand = RACCommand(signalBlock: { (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    subscriber.sendCompleted()
                    
                    return RACDisposable(block: { () -> Void in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
            })
            
        }
        // TweetDetailViewController
        else if segue.identifier == "fromMainToTweetDetail" {
            var tweetDetailViewController:TWPTweetDetailViewController = segue.destinationViewController as! TWPTweetDetailViewController
            
            // TODO: bad solution
            tweetDetailViewController.tempTweetID = self.selectedTweetID
            
            // bind Next ViewController's Commands
            tweetDetailViewController.backButtonCommand = RACCommand(signalBlock: { (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    subscriber.sendCompleted()
                    
                    return RACDisposable(block: { () -> Void in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
            })
        }
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Alert
    func showAlertWithTitle(title: String?, message: String?) {
        if objc_getClass("UIAlertController") != nil {
            // use UIAlertController
            var alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                println("Cancel Button tapped")
            })
            alertController.addAction(cancelAction)
            
            presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            // use UIAlertView
            var alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: "OK")
            alertView.show()
        }
    }
    
    // MARK: - Common Handler
    let errorHandler: ((NSError!) -> Void) = {
        error in
        
        if error != nil {
            println("ViewController's error:\(error.localizedDescription)")
        }
        else {
            println("ViewController's error is nil")
        }
    }
    let completedHandler: (() -> Void) = {
        println("ViewController's completed!")
    }
    
    // MARK: - Binding
    func bindCommands() {
        
        // bind Button to the RACCommand
        self.accountButton.rac_command = self.model.accountButtonCommand
        self.oauthButton.rac_command = self.model.oauthButtonCommand
        self.feedUpdateButton.rac_command = self.model.feedUpdateButtonCommand
        
        // subscribe ViewModel's RACSignal
        // Completed Signals
        self.accountButton.rac_command.executionSignals.flatten().subscribeNext { (next) -> Void in
            self.showAlertWithTitle("SUCCESS!", message: "authorize success!")
        }
        self.oauthButton.rac_command.executionSignals.flatten().subscribeNext { (next) -> Void in
            self.showAlertWithTitle("SUCCESS!", message: "authorize success!")
        }
        self.feedUpdateButton.rac_command.executionSignals.flatten().subscribeNext { (next) -> Void in
            self.showAlertWithTitle("SUCCESS!", message: "feed update success!")
        }
        
        // Error Signals
        self.accountButton.rac_command.errors.subscribeNext { (error) -> Void in
            println("Account authorize error!:\(error)")
            if error != nil {
                self.showAlertWithTitle("ERROR!", message: error.localizedDescription)
            }
        }
        self.oauthButton.rac_command.errors.subscribeNext { (error) -> Void in
            println("OAuth authorize error!:\(error)")
            if error != nil {
                self.showAlertWithTitle("ERROR!", message: error.localizedDescription)
            }
        }
        self.feedUpdateButton.rac_command.errors.subscribeNext { (error) -> Void in
            println("feed update error:\(error)")
            if error != nil {
                self.showAlertWithTitle("ERROR!", message: error.localizedDescription)
            }
        }
    
        // bind ViewModel's parameter
        self.model.rac_valuesForKeyPath("tapCount", observer: self).subscribeNext { (tapCount) -> Void in
            println(tapCount)
        }        // TODO: 後で消す
        self.model.rac_valuesForKeyPath("tweets", observer: self).subscribeNext { (tweets) -> Void in
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    func tableViewButtonsTouch(sender: UIButton, event: UIEvent) {
        var touch: UITouch = event.allTouches()?.first as! UITouch
        var point = touch.locationInView(self.tableView)
        var indexPath = self.tableView.indexPathForRowAtPoint(point)
        
        var type: TWPMainTableViewButtonType = TWPMainTableViewButtonType(rawValue: sender.tag)!
        switch type {
        case .reply:
            println("reply button tapped index:\(indexPath!.row)")
            break
        case .retweet:
            self.model.postStatusRetweetWithIndex(indexPath!.row,
                success: { () -> Void in
                    println("retweet success!")
                    self.tableView.reloadData()
            }, failure: { (error) -> Void in
                println("retweet error:\(error)")
            })

            break
        case .favorite:
            println("favorite button tapped index:\(indexPath!.row)")
            break
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.model.tweets.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:TWPMainViewControllerTableViewCell! = tableView.dequeueReusableCellWithIdentifier(kTWPMainTableViewCellIdentifier) as? TWPMainViewControllerTableViewCell
        
        // create Tweet Object
        var tweet:TWPTweet = self.model.tweets[indexPath.row] as! TWPTweet
        
        // set Cell Items
        cell.iconImageView.sd_setImageWithURL(tweet.user?.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: SDWebImageOptions.CacheMemoryOnly)
        cell.tweetTextLabel.text = tweet.text
        cell.userNameLabel.text = tweet.user?.name
        cell.screenNameLabel.text = tweet.user?.screenNameWithAt
        cell.retweetButton.selected = tweet.retweeted!
        
        // set Cell Actions
        cell.replyButton.tag = TWPMainTableViewButtonType.reply.rawValue
        cell.replyButton.addTarget(self, action: "tableViewButtonsTouch:event:", forControlEvents: .TouchUpInside)
        
        cell.retweetButton.tag = TWPMainTableViewButtonType.retweet.rawValue
        cell.retweetButton.addTarget(self, action: "tableViewButtonsTouch:event:", forControlEvents: .TouchUpInside)
        
        cell.favoriteButton.tag = TWPMainTableViewButtonType.favorite.rawValue
        cell.favoriteButton.addTarget(self, action: "tableViewButtonsTouch:event:", forControlEvents: .TouchUpInside)
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120.0
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedTweet: TWPTweet = self.model.tweets[indexPath.row] as! TWPTweet;
        self.selectedTweetID = selectedTweet.tweetID
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("fromMainToTweetDetail", sender: nil)
        
    }

    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == alertView.cancelButtonIndex {
            println("AlertView cancel button tapped.")
        }
        else {
            
        }
    }

}

