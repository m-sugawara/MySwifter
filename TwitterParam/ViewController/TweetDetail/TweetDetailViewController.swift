//
//  TweetDetailViewController.swift
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

class TweetDetailViewController: UIViewController, TTTAttributedLabelDelegate {

    var model: TweetDetailViewModel!

    var tempTweetID:String!
    var backButtonAction: Action<Void, Void, Error>?

    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var tweetLabel: TTTAttributedLabel!
    @IBOutlet private weak var userIconImageView: UIImageView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var screenNameLabel: UILabel!

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        bindActions()
        configureViews()

        model.getTweet(with: tempTweetID).startWithResult { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.updateSubviews()
            case .failure(let error):
                self.showAlert(with: "ERROR", message: "failed to get tweet. \(error)")
            }
        }
    }

    // MARK: - Binding
    private func bindActions() {
        if let backButtonAction = backButtonAction {
            backButton.reactive.pressed = CocoaAction(backButtonAction)
        }
    }

    // MARK: - Private Methods
    private func configureViews() {
        tweetLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
    }

    private func updateSubviews() {
        tweetLabel.text = model.tweet?.text
        userIconImageView.sd_setImage(
            with: model.tweet?.user?.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: .fromCacheOnly,
            completed: nil
        )
    }

    // MARK: - TTTAttributedLabelDelegate
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}
