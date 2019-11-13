//
//  MainViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import ReactiveSwift
import TTTAttributedLabel
import UITextFieldWithLimit
import SDWebImage

let kTWPMainTableViewCellIdentifier = "MainTableViewCell";
let kTextFieldMaxLength = 140;
let kTextFieldMarginWidth: CGFloat = 20.0;
let kTextFieldMarginHeight: CGFloat = 20.0;

enum TWPMainTableViewButtonType: Int {
    case reply = 1
    case retweet
    case favorite
}

class TWPMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIScrollViewDelegate, UITextFieldWithLimitDelegate, TTTAttributedLabelDelegate {
    let model = TWPMainViewModel()
    var textFieldView: TWPTextFieldView?
    var userID: String!
    var selectedTweetID: String!
    
    var scrollBeginingPoint: CGPoint!
    var footerViewHidden: Bool!
    
    var logoutButtonCommand: RACCommand!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tweetButton: UIButton!
    @IBOutlet weak var feedUpdateButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var footerViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Deinit
    deinit {
        self.stopObserving()
    }
    
    // MARK: - Disignated Initializer
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.startObserving()
        
        self.configureViews()
        
        self.bindParameters()
        self.bindCommands()
        
        // bind tableView Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        // first, load current user's home timeline
        self.startLoading()
        self.model.feedUpdateButtonSignal().subscribeError({ (error) -> Void in
            self.stopLoading()
            self.showAlertWithTitle("ERROR", message: error.localizedDescription)
        }, completed: { () -> Void in
            self.stopLoading()
            print("first feed update completed!")
        })

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // UserInfoViewController
        if segue.identifier == "fromMainToUserInfo" {
            let userInfoViewController:TWPUserInfoViewController = segue.destination as! TWPUserInfoViewController
            
            // TODO: bad solution
            userInfoViewController.tempUserID = TWPUserHelper.currentUserID()
            
            // bind Next ViewController's Commands
            //            let action = Action<(), Void?, Error> {
            //                return SignalProducer {
            //                    self.dismiss(animated: true, completion: nil)
            //                }
            //            }
            //            userInfoViewController.backButton.reactive.pressed = CocoaAction(action)
            _ = userInfoViewController.backButton.reactive.trigger(for: #selector(UIViewController.dismiss(animated:completion:)))
            
        }
            // TweetDetailViewController
        else if segue.identifier == "fromMainToTweetDetail" {
            var tweetDetailViewController:TWPTweetDetailViewController = segue.destination as! TWPTweetDetailViewController
            
            // TODO: bad solution
            tweetDetailViewController.tempTweetID = self.selectedTweetID
            
            // bind Next ViewController's Commands
            _ = tweetDetailViewController.backButton.reactive.trigger(for: #selector(UIViewController.dismiss(animated:completion:)))
        }
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Private Methods
    func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    func stopObserving() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    func startLoading() {
        self.loadingView.isHidden = false
        self.activityIndicatorView.startAnimating()
    }
    
    func stopLoading() {
        self.loadingView.isHidden = true
        self.activityIndicatorView.stopAnimating()
    }
    
    func configureViews() {
        self.textFieldView = TWPTextFieldView.viewWithMaxLength(maxLength: kTextFieldMaxLength, delegate: self)
        self.textFieldView?.alpha = 0.0

        self.view.addSubview(self.textFieldView!)
    }
    
    @objc func showTextFieldView(screenName:String? = "") {
        for view in view.subviews {
            if view is TWPTextFieldView {
                continue
            }
            view.isUserInteractionEnabled = false
        }
        
        var defaultScreenName = ""
        if screenName != "" {
            defaultScreenName = "@" + screenName! + ": "
        }
        
        self.textFieldView?.alpha = 0.01;
        self.textFieldView?.textFieldWithLimit.becomeFirstResponder()
        self.textFieldView?.textFieldWithLimit.text = defaultScreenName
        self.textFieldView?.textFieldWithLimit.limitLabel.text = String(kTextFieldMaxLength)
    }
    
    func hideTextFieldView() {
        for view in view.subviews {
            if view is TWPTextFieldView {
                continue
            }
            view.isUserInteractionEnabled = true
        }
        
        // reset selecting Index, when hide textfield view.
        self.model.selectingIndex = kNotSelectIndex
        
        self.textFieldView?.alpha = 0.0
        self.textFieldView?.textFieldWithLimit.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        // get frame of keyboard from userinfo
        guard let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let keyboardAnimationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
        }
        
        // update textfield view frame
        let textFieldViewOriginX = kTextFieldMarginWidth
        let textFieldViewOriginY = keyboardFrame.origin.y - self.textFieldView!.frame.size.height - kTextFieldMarginHeight
        let textFieldViewSizeWidth = self.view.frame.size.width - (kTextFieldMarginWidth * 2)
        let textFieldViewSizeHeight = self.textFieldView!.frame.size.height
        
        self.textFieldView!.frame = CGRect(
            x: textFieldViewOriginX,
            y: textFieldViewOriginY,
            width: textFieldViewSizeWidth,
            height: textFieldViewSizeHeight)
        
        // show textfield view with animation.
        UIView.animate(withDuration: keyboardAnimationDuration, animations: { () -> Void in
            self.textFieldView?.alpha = 1.0
        })
        
    }

    
    // MARK: - Common Handler
    let errorHandler: ((Error?) -> Void) = {
        error in
        if let error = error as NSError? {
            print("ViewController's error:\(error.localizedDescription)")
        }
        else {
            print("ViewController's error is nil")
        }
    }
    let completedHandler: (() -> Void) = {
        print("ViewController's completed!")
    }
    
    // MARK: - Binding
    func bindParameters() {
        textFieldView?.textFieldWithLimit.reactive.text <~ model.inputtingTweet
    }
    
    func bindCommands() {
        
        // bind Button to the RACCommand
        _ = tweetButton.reactive.trigger(for: #selector(showTextFieldView(screenName:)))

        feedUpdateButton.reactive.pressed = CocoaAction(model.feedUpdateButtonCommand)
        logoutButton.rac_command = self.logoutButtonCommand
        
        // TWPTextFieldView Commands
        self.textFieldView?.cancelButton.rac_command = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
            return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                subscriber.sendCompleted()
                
                self?.hideTextFieldView()

                return RACDisposable()
            })
        })
        
        self.textFieldView?.tweetButton.rac_command = self.model.tweetButtonCommand
        
        // subscribe ViewModel's RACSignal
        // Completed Signals
        self.feedUpdateButton.rac_command.executionSignals.flatten().subscribeNext { [weak self] (next) -> Void in
            self!.showAlertWithTitle("SUCCESS!", message: "feed update success!")
        }
        self.textFieldView?.tweetButton.rac_command.executionSignals.flatten().subscribeNext({ [weak self] (next) -> Void in
            self?.hideTextFieldView()
            
            self?.showAlertWithTitle("SUCCESS!", message: "tweet success!")
            
            // if tweet update success, feed update.
            self!.model.feedUpdateButtonSignal().subscribeNext({ (next) -> Void in
                
            }, error: { (error) -> Void in
                self!.showAlertWithTitle("ERROR", message: error.localizedDescription)
            })
            
        })
        
        // Error Signals
        self.feedUpdateButton.rac_command.errors.subscribeNext { [weak self] (error) -> Void in
            print("feed update error:\(error)")
            if error != nil {
                self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
            }
        }
        self.textFieldView?.tweetButton.rac_command.errors.subscribeNext({ [weak self] (error) -> Void in
            self?.hideTextFieldView()
            print("tweet error:\(error)")
            if error != nil {
                self!.showAlertWithTitle("ERROR!", message: error.localizedDescription)
            }
        })
        


        // bind ViewModel's parameter
        self.model.rac_valuesForKeyPath("tapCount", observer: self).subscribeNext { (tapCount) -> Void in
            print(tapCount)
        }
        // TODO: 後で消す
        self.model.rac_valuesForKeyPath("tweets", observer: self).subscribeNext { [weak self] (tweets) -> Void in
            self!.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    func tableViewButtonsTouch(sender: UIButton, event: UIEvent) {
        // get indexpath from touch point
        var touch: UITouch = event.allTouches()?.first as! UITouch
        var point = touch.locationInView(self.tableView)
        var indexPath = self.tableView.indexPathForRowAtPoint(point)
        
        // set selecting Index to ViewModel
        self.model.selectingIndex = indexPath!.row
        
        var type: TWPMainTableViewButtonType = TWPMainTableViewButtonType(rawValue: sender.tag)!
        switch type {
        case .reply:
            print("reply button tapped index:\(indexPath!.row)")
            self.showTextFieldView(screenName: self.model.selectingTweetScreenName())
            
            break
        case .retweet:
            self.model.postStatusRetweetSignalWithIndex(indexPath!.row).subscribeError({ [weak self] (error) -> Void in
                print("retweet error:\(error)")
                self!.showAlertWithTitle("ERROR", message: error.localizedDescription)
                self!.model.selectingIndex = kNotSelectIndex
                }, completed: { [weak self] () -> Void in
                    print("retweet success!")
                    self!.tableView.reloadData()
                    self!.model.selectingIndex = kNotSelectIndex
            })
            break
        case .favorite:
            self.model.postFavoriteSignalWithIndex(indexPath!.row).subscribeError({ [weak self] (error) -> Void in
                print("favorite error:\(error)")
                self!.showAlertWithTitle("ERROR", message: error.localizedDescription)
                self!.model.selectingIndex = kNotSelectIndex
                }, completed: { [weak self] () -> Void in
                    print("favorite success!")
                    self!.tableView.reloadData()
                    self!.model.selectingIndex = kNotSelectIndex
            })
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
        cell.tweetTextLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        cell.userNameLabel.text = tweet.user?.name
        cell.screenNameLabel.text = tweet.user?.screenNameWithAt
        cell.retweetCountLabel.text = String(tweet.retweetCount!)
        cell.favoriteCountLabel.text = String(tweet.favoriteCount!)
        
        cell.retweetButton.selected = tweet.retweeted!
        cell.favoriteButton.selected = tweet.favorited!
        
        cell.timeLabel.text = tweet.createdAt?.stringForTimeIntervalSinceCreated()
        
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
        return 130.0
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedTweet: TWPTweet = self.model.tweets[indexPath.row] as! TWPTweet;
        self.selectedTweetID = selectedTweet.tweetID
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier("fromMainToTweetDetail", sender: nil)
        
    }
    
    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollBeginingPoint = scrollView.contentOffset
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var currentPoint = scrollView.contentOffset
        if (scrollBeginingPoint.y < currentPoint.y) {
            scrollDown()
        }
        else {
            scrollUp()
        }
    }
    
    func scrollDown() {
        if footerViewHidden != true {
            self.footerViewHidden = true
            UIView.animateWithDuration(0.5,
                                       animations: { () -> Void in
                                        self.tweetButton.hidden = true
                                        self.footerViewHeightConstraint.constant = 0.0
                                        self.view.layoutIfNeeded()

            })
        }
    }

    func scrollUp() {
        if self.footerViewHidden == true {
            self.footerViewHidden = false
            UIView.animateWithDuration(0.5,
                                       animations: { () -> Void in
                                        self.footerViewHeightConstraint.constant = 70.0
                                        self.tweetButton.hidden = false
                                        self.view.layoutIfNeeded()
            })
        }
    }

    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == alertView.cancelButtonIndex {
            print("AlertView cancel button tapped.")
        }
        else {
            
        }
    }
    
    // MARK: - TTTAttributedLabelDelegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }

}

