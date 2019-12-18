//
//  TWPUserInfoViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/03.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import ReactiveSwift
import TTTAttributedLabel
import SDWebImage

let kTWPUserInfoTableViewCellIdentifier = "UserInfoTableViewCell"

class TWPUserInfoViewController: UIViewController {

    enum ListType {
        case followList
        case followerList
    }

    let model = TWPUserInfoViewModel()

    var selectingUserList: ListType?
    var tempUserID: String!
    var backButtonAction: CocoaAction<UIButton>!

    var selectedTweetID: String!

    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var screenNameLabel: UILabel!
    @IBOutlet private weak var userIconImageView: UIImageView!
    @IBOutlet private weak var userTweetsTableView: UITableView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var followListButton: UIButton!
    @IBOutlet private weak var followerListButton: UIButton!
    @IBOutlet private weak var followButton: UIButton!
    @IBOutlet private weak var tweetListButton: UIButton!
    @IBOutlet private weak var imageListButton: UIButton!
    @IBOutlet private weak var favoriteListButton: UIButton!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    deinit {
        print("userInfo deinit")
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {

        super.viewDidLoad()

        bindCommands()

        // view did show for the firsttime, load user's timeline
        if tempUserID != nil {
            model.userId = tempUserID

            // set default status
            if model.userId == TWPUserHelper.currentUserID() {
                followButton.isHidden = true
            }

            // get user info
            startLoading()
            model.getUserInfo().startWithResult { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.setUserProfile()
                    self.model.getUserTimeline().startWithResult { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success:
                            self.tableView.reloadData()
                            self.stopLoading()
                        case .failure:
                            self.showAlert(with: "ERROR", message: "failed to get timeline")
                        }
                    }
                case .failure:
                    self.showAlert(with: "ERROR", message: "failed to get userInfo")
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard tempUserID != nil else {
            showAlert(
                with: "ERROR!",
                message: "user not found!",
                cancelButtonTitle: "Back",
                cancelTappedAction: { [weak self] _ in
                    self?.dismiss(animated: true, completion: nil)
            })
            return
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        let action = Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { observer, _ in
                self.dismiss(animated: true, completion: nil)
                observer.sendCompleted()
            }
        }
        if let tweetDetailViewController = segue.destination as? TWPTweetDetailViewController,
            segue.identifier == "fromUserInfoToTweetDetail" {
            tweetDetailViewController.tempTweetID = self.selectedTweetID
            tweetDetailViewController.backButtonCommand = CocoaAction(action)

        } else if let userListViewController = segue.destination as? TWPUserListViewController,
            segue.identifier == "fromUserInfoToUserList" {
            userListViewController.tempUserID = self.tempUserID
            userListViewController.backButtonAction = CocoaAction(action)
        }
    }

    // MARK: - Binding

    func bindCommands() {
        self.backButton.reactive.pressed = self.backButtonAction

        // follow list button
        followListButton.reactive.pressed = CocoaAction<UIButton>(Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { observer, lifetime in
                guard !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }
                self.selectingUserList = .followList
                self.performSegue(withIdentifier: "fromUserInfoToUserList", sender: nil)
                observer.sendCompleted()
            }
        })

        // follower list button
        followerListButton.reactive.pressed = CocoaAction<UIButton>(Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { observer, lifetime in
                guard !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }
                self.selectingUserList = .followerList
                self.performSegue(withIdentifier: "fromUserInfoToUserList", sender: nil)
                observer.sendCompleted()
            }
        })

        // follow button
        followButton.reactive.pressed = CocoaAction(model.followAction)
//        followButton.isSelected <~ model.user!.following

        // SelectListButtons
        tweetListButton.reactive.pressed = CocoaAction(model.getUserTimeLineAction)

        // ImageListButton
        imageListButton.reactive.pressed = CocoaAction(model.getUserImageListAction)

        // FavoriteListButton
        favoriteListButton.reactive.pressed = CocoaAction(model.getUserFavoritesAction)
    }

    func showAlert(with error: TWPUserInfoViewModel.UserInfoViewModelError) {
        showAlert(with: "ERROR", message: error.message)
    }

    // MARK: - Private Methods
    func startLoading() {
        self.loadingView.isHidden = false
        self.activityIndicatorView.startAnimating()
    }

    func stopLoading() {
        self.loadingView.isHidden = true
        self.activityIndicatorView.stopAnimating()
    }

    func setUserProfile() {
        userNameLabel.text = model.user?.name

        followListButton.setTitle(
            String(model.user!.friendsCount) + " follows",
            for: .normal
        )
        followerListButton.setTitle(
            String(model.user!.followersCount) + " followers",
            for: .normal
        )

        if model.user?.screenName != nil {
            screenNameLabel.text = self.model.user?.screenNameWithAt
        } else {
            screenNameLabel.text = "no data"
        }

        userIconImageView.sd_setImage(with: model.user?.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: .fromCacheOnly)

        followButton.isSelected = model.user?.following ?? false
    }

    func changeStatus(of tappedButton: UIButton) {
        let listButtons: [UIButton] = [
            tweetListButton,
            imageListButton,
            favoriteListButton
        ]

        for listButton in listButtons {
            if listButton == tappedButton {
                listButton.isSelected = true
                listButton.backgroundColor = .lightGray
            } else {
                listButton.isSelected = false
                listButton.backgroundColor = .clear
            }
        }
    }

}

extension TWPUserInfoViewController: UITableViewDataSource {
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.tweets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: kTWPUserInfoTableViewCellIdentifier
            ) as? TWPUserInfoViewControllerTableViewCell else {
                fatalError()
        }
        let tweet = self.model.tweets[indexPath.row]

        cell.iconImageView.sd_setImage(with: tweet.user?.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: .fromCacheOnly)
        cell.tweetTextLabel.text = tweet.text
        cell.tweetTextLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension TWPUserInfoViewController: UITableViewDelegate {
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTweet = self.model.tweets[indexPath.row]
        self.selectedTweetID = selectedTweet.tweetId

        tableView.deselectRow(at: indexPath, animated: true)

        performSegue(withIdentifier: "fromUserInfoToTweetDetail", sender: nil)
    }
}

extension TWPUserInfoViewController: TTTAttributedLabelDelegate {
    // MARK: - TTTAttributedLabelDelegate
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url)
    }
}
