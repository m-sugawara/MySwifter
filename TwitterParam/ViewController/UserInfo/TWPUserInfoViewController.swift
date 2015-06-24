//
//  TWPUserInfoViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

let kTWPUserInfoTableViewCellIdentifier = "UserInfoTableViewCell";

class TWPUserInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TTTAttributedLabelDelegate {
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
    @IBOutlet weak var tweetListButton: UIButton!
    @IBOutlet weak var imageListButton: UIButton!
    @IBOutlet weak var favoriteListButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    deinit {
        println("userInfo deinit")
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.bindCommands()
        
        if self.tempUserID != nil {
            // TODO: bad solution
            self.model.userID = self.tempUserID
            
            // get user info
            self.startLoading()
            self.model.getUserInfoSignal().subscribeNext({ (user) -> Void in
                println("viewController.user:\(user)")
                }, error: { (error) -> Void in
                    println("viewController.error:\(error)")
                }) { [weak self] () -> Void in
                    self!.setUserProfile()
                    
                    println("viewController's get userinfo completed")
                    
                    self!.model.getUserTimelineSignal().subscribeError({ (error) -> Void in
                        println("getUserTimeline.error:\(error)")
                        self!.stopLoading()
                        }, completed: { () -> Void in
                            self!.tableView.reloadData()
                            self!.stopLoading()
                            println("getUserTimeline completed!")
                    })
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if self.tempUserID == nil {
            self.showAlertWithTitle("ERROR!", message: "user not found!", cancelButtonTitle: "Back", cancelTappedAction: { () -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
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
    }
    
    // MARK: - Binding
    func bindCommands() {
        self.backButton.rac_command = self.backButtonCommand
        
        // SelectListButtons
        self.tweetListButton.rac_command = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in

                // get users timeline
                self!.startLoading()
                self!.model.getUserTimelineSignal().subscribeError({ (error) -> Void in
                    println("getUserTimeline.error:\(error)")
                    self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
                    self!.stopLoading()
                    subscriber.sendCompleted()
                    }, completed: { () -> Void in
                        self!.tableView.reloadData()
                        
                        self!.stopLoading()
                        self!.changeListButtonsStatusWithTappedButton(input as! UIButton)
                        
                        subscriber.sendCompleted()
                        println("getUserTimeline completed!")
                })

                return RACDisposable()
            })
        })
        self.imageListButton.rac_command = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in

                // get users imagelist
                self!.startLoading()
                self!.model.getUserImageList().subscribeError({ (error) -> Void in
                    println("getUserTimeline.error:\(error)")
                    self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
                    self!.stopLoading()
                    subscriber.sendCompleted()
                    }, completed: { () -> Void in
                        self!.tableView.reloadData()
                        
                        self!.changeListButtonsStatusWithTappedButton(input as! UIButton)
                        self!.stopLoading()
                        
                        subscriber.sendCompleted()
                        println("getUserTimeline completed!")
                })
                
                return RACDisposable()
            })
        })
        self.favoriteListButton.rac_command = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                // get users favoritelist
                self!.startLoading()
                self!.model.getUserFavoritesList().subscribeError({ (error) -> Void in
                    println("getUserTimeline.error:\(error)")
                    self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
                    self!.stopLoading()
                    subscriber.sendCompleted()
                    }, completed: { () -> Void in
                        self!.tableView.reloadData()
                        
                        self!.changeListButtonsStatusWithTappedButton(input as! UIButton)
                        self!.stopLoading()
                        
                        subscriber.sendCompleted()
                        println("getUserTimeline completed!")
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
