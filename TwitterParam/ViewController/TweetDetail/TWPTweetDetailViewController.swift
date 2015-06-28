//
//  TWPTweetDetailViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/19.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import TTTAttributedLabel
import ReactiveCocoa
import SDWebImage

class TWPTweetDetailViewController: UIViewController, TTTAttributedLabelDelegate {
    let model = TWPTweetDetailViewModel()
    
    var tempTweetID:String!
    var backButtonCommand:RACCommand!

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tweetLabel: TTTAttributedLabel!
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    
    // MARK: - Deinit
    deinit {
        println("tweetdetail deinit")
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.bindCommands()
        
        self.configureViews()
        
        // TODO: Bad Solution
        self.model.tweetID = self.tempTweetID
        self.model.getTweetSignal()?.subscribeError({ (error) -> Void in
            println("error:\(error)")
        }, completed: { [weak self] () -> Void in
            self!.tweetLabel.text = self!.model.tweet?.text
            self!.userIconImageView.sd_setImageWithURL(self!.model.tweet?.user?.profileImageUrl,
                placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
                options: SDWebImageOptions.CacheMemoryOnly)
            self!.screenNameLabel.text = self!.model.tweet?.user?.screenNameWithAt
            self!.userNameLabel.text = self!.model.tweet?.user?.name
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if segue.identifier == "fromTweetDetailToUserInfo" {
            var userInfoViewController: TWPUserInfoViewController = segue.destinationViewController as! TWPUserInfoViewController
            userInfoViewController.tempUserID = self.model.tweet?.user?.userID
            
            // regist backbutton command
            userInfoViewController.backButtonCommand = RACCommand(signalBlock: { [weak self] (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    subscriber.sendCompleted()
                    
                    return RACDisposable(block: { () -> Void in
                        self!.dismissViewControllerAnimated(true, completion: nil)
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
    
    // MARK: - Binding
    func bindCommands() {
        self.backButton.rac_command = self.backButtonCommand
        
    }
    
    // MARK: - Private Methods
    func configureViews() {
        self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
    }
    
    // MARK: - TTTAttributedLabelDelegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }

}
