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
import ReactiveSwift
import SDWebImage

class TWPTweetDetailViewController: UIViewController, TTTAttributedLabelDelegate {
    let model = TWPTweetDetailViewModel()
    
    var tempTweetID:String!
    var backButtonCommand: CocoaAction<UIButton>?

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var tweetLabel: TTTAttributedLabel!
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.bindCommands()
        
        self.configureViews()
        
        // TODO: Bad Solution
        self.model.tweetId = self.tempTweetID
        self.model.getTweetSignalProducer().startWithResult { result in
            switch result {
            case .success:
                let tweet = self.model.tweet!
                self.tweetLabel.text = tweet.text
                self.userIconImageView.sd_setImage(
                    with: tweet.user?.profileImageUrl,
                    placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
                    options: .fromCacheOnly,
                    completed: nil
                )
            case .failure(let error):
                print("error: \(error)")
                self.showAlert(with: "ERROR", message: "failed to get tweet")
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "fromTweetDetailToUserInfo" {
            let userInfoViewController = segue.destination as! TWPUserInfoViewController
            userInfoViewController.tempUserID = self.model.tweet?.user?.userID
            
            // regist backbutton command
            userInfoViewController.backButtonAction = CocoaAction(Action<Void, Void, Error> { _ in
                return SignalProducer<Void, Error> { observer, _ in
                    self.dismiss(animated: true, completion: nil)
                    observer.sendCompleted()
                }
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
        self.backButton.reactive.pressed = self.backButtonCommand
    }
    
    // MARK: - Private Methods
    func configureViews() {
        self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
    }
    
    // MARK: - TTTAttributedLabelDelegate
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}
