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

        bindCommands()
        configureViews()

        model.tweetId = tempTweetID
        model.getTweetSignalProducer().startWithResult { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                let tweet = self.model.tweet
                self.tweetLabel.text = tweet?.text
                self.userIconImageView.sd_setImage(
                    with: tweet?.user?.profileImageUrl,
                    placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
                    options: .fromCacheOnly,
                    completed: nil
                )
            case .failure(let error):
                self.showAlert(with: "ERROR", message: "failed to get tweet. \(error)")
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let userInfoViewController = segue.destination as? TWPUserInfoViewController,
            segue.identifier == "fromTweetDetailToUserInfo" {
            userInfoViewController.tempUserID = self.model.tweet?.user?.userId

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
