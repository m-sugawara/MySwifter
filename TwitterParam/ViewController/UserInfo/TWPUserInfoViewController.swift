//
//  TWPUserInfoViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import TTTAttributedLabel
import SDWebImage

let kTWPUserInfoTableViewCellIdentifier = "UserInfoTableViewCell";

enum TWPUserListType {
    case followList
    case followerList
}

class TWPUserInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TTTAttributedLabelDelegate {
    let model = TWPUserInfoViewModel()
    
    var selectingUserList: TWPUserListType?
    var tempUserID: String!
    var backButtonCommand: RACCommand!
    
    var selectedTweetID: String!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var userTweetsTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var followListButton: UIButton!
    @IBOutlet weak var followerListButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var tweetListButton: UIButton!
    @IBOutlet weak var imageListButton: UIButton!
    @IBOutlet weak var favoriteListButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    deinit {
        print("userInfo deinit")
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.bindCommands()
        
        // view did show for the firsttime, load user's timeline
        if self.tempUserID != nil {
            // TODO: bad solution
            self.model.userID = self.tempUserID
            
            // set default status
            if self.model.userID == TWPUserHelper.currentUserID() {
                self.followButton.isHidden = true
            }
            
            // get user info
            self.startLoading()
            self.model.getUserInfoSignal().start({ (user) -> Void in
                }, error: { (error) -> Void in
                }) { [weak self] () -> Void in
                    self!.setUserProfile()
                    self!.model.getUserTimelineSignal().startWithFailed({ error in
                        print("getUserTimeline.error:\(error)")
                        self!.stopLoading()
                        }, completed: { () -> Void in
                            self!.tableView.reloadData()
                            self!.stopLoading()
                            print("getUserTimeline completed!")
                    })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // this method doesn't work, viewWillLoad:, therefore alert show here.
        if self.tempUserID == nil {
            self.showAlertWithTitle(title: "ERROR!", message: "user not found!", cancelButtonTitle: "Back", cancelTappedAction: { () -> Void in
                self.dismiss(animated: true, completion: nil)
            })
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if segue.identifier == "fromUserInfoToTweetDetail" {
            var tweetDetailViewController: TWPTweetDetailViewController = segue.destinationViewController as! TWPTweetDetailViewController
            
            tweetDetailViewController.tempTweetID = self.selectedTweetID
            
            tweetDetailViewController.backButtonCommand = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    // send completed for button status to acitive
                    subscriber.sendCompleted()
                    
                    return RACDisposable(block: { () -> Void in
                        self!.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
            })
        
        }
        else if segue.identifier == "fromUserInfoToUserList" {
            var userListViewController: TWPUserListViewController = segue.destinationViewController as! TWPUserListViewController
            userListViewController.tempUserID = self.tempUserID
            
            userListViewController.backButtonCommand = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    // send completed for button status to acitive
                    subscriber.sendCompleted()
                    
                    return RACDisposable(block: { () -> Void in
                        self!.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
                })
        }
    }
    
    // MARK: - Binding
    
    func bindCommands() {
        self.backButton.rac_command = self.backButtonCommand
        
        // follow list button
        self.followListButton.rac_command = RACCommand(signalBlock: { (input) -> RACSignal! in
            return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
                self!.selectingUserList = TWPUserListType.followList
                
                self!.performSegueWithIdentifier("fromUserInfoToUserList", sender: nil)
                
                subscriber.sendCompleted()
                
                return RACDisposable()
            })
        })
        // follower list button
        self.followerListButton.rac_command = RACCommand(signalBlock: { (input) -> RACSignal! in
            return RACSignal.createSignal({ [weak self] (subscriber) -> RACDisposable! in
                self!.selectingUserList = TWPUserListType.followerList

                self!.performSegueWithIdentifier("fromUserInfoToUserList", sender: nil)
                
                subscriber.sendCompleted()
                
                return RACDisposable()
                })
        })
        
        // follow button
        self.followButton.rac_command = self.model.followButtonCommand
        self.followButton.rac_command.executionSignals.flatten().subscribeNext { [weak self] (next) -> Void in
            self!.followButton.selected = self!.model.user.following!
        }
        self.followButton.rac_command.errors.subscribeNext { [weak self] (error) -> Void in
            print("user follow error:\(error)")
            self!.showAlertWithTitle("ERROR", message:error.localizedDescription)
        }
        
        // SelectListButtons
        self.tweetListButton.rac_command = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in

                // get users timeline
                self!.startLoading()
                self!.model.getUserTimelineSignal().subscribeError({ (error) -> Void in
                    print("getUserTimeline.error:\(error)")
                    self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
                    self!.stopLoading()
                    subscriber.sendCompleted()
                    }, completed: { () -> Void in
                        self!.tableView.reloadData()
                        
                        self!.stopLoading()
                        self!.changeListButtonsStatusWithTappedButton(input as! UIButton)
                        
                        subscriber.sendCompleted()
                        print("getUserTimeline completed!")
                })

                return RACDisposable()
            })
        })
        self.imageListButton.rac_command = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in

                // get users imagelist
                self!.startLoading()
                self!.model.getUserImageList().subscribeError({ (error) -> Void in
                    print("getUserTimeline.error:\(error)")
                    self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
                    self!.stopLoading()
                    subscriber.sendCompleted()
                    }, completed: { () -> Void in
                        self!.tableView.reloadData()
                        
                        self!.changeListButtonsStatusWithTappedButton(input as! UIButton)
                        self!.stopLoading()
                        
                        subscriber.sendCompleted()
                        print("getUserTimeline completed!")
                })
                
                return RACDisposable()
            })
        })
        self.favoriteListButton.rac_command = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                // get users favoritelist
                self!.startLoading()
                self!.model.getUserFavoritesList().subscribeError({ (error) -> Void in
                    print("getUserTimeline.error:\(error)")
                    self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
                    self!.stopLoading()
                    subscriber.sendCompleted()
                    }, completed: { () -> Void in
                        self!.tableView.reloadData()
                        
                        self!.changeListButtonsStatusWithTappedButton(input as! UIButton)
                        self!.stopLoading()
                        
                        subscriber.sendCompleted()
                        print("getUserTimeline completed!")
                })

                return RACDisposable()
            })
        })
    }
    
    // MARK: - Private Methods
    func startLoading() {
        self.loadingView.hidden = false
        self.activityIndicatorView.startAnimating()
    }
    
    func stopLoading() {
        self.loadingView.hidden = true
        self.activityIndicatorView.stopAnimating()
    }
    
    func setUserProfile() {
        self.userNameLabel.text = self.model.user.name
        
        self.followListButton.setTitle(String(self.model.user.friendsCount!) + " follows",
            forState: UIControlState.Normal)
        self.followerListButton.setTitle(String(self.model.user.followersCount!) + " followers",
            forState: UIControlState.Normal)
        
        
        if self.model.user.screenName != nil {
            self.screenNameLabel.text = self.model.user.screenNameWithAt!
        }
        else {
            self.screenNameLabel.text = "no data"
        }
        
        self.userIconImageView.sd_setImageWithURL(self.model.user.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: SDWebImageOptions.CacheMemoryOnly)
        
        self.followButton.selected = self.model.user.following!
    }
    
    func changeListButtonsStatusWithTappedButton(tappedButton: UIButton) {
        let listButtons: Array<UIButton> = [self.tweetListButton, self.imageListButton, self.favoriteListButton]
        
        for listButton in listButtons {
            if listButton == tappedButton {
                listButton.selected = true
                listButton.backgroundColor = UIColor.lightGrayColor()
            }
            else {
                listButton.selected = false
                listButton.backgroundColor = UIColor.clearColor()
            }
        }
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
        cell.tweetTextLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        
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
    
    // MARK: - TTTAttributedLabelDelegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
}
