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

class TWPUserInfoViewController: UIViewController {

    enum ListType {
        case followList
        case followerList
    }

    private let model = TWPUserInfoViewModel()

    var selectingUserList: ListType?
    var tempUserID: String!
    var backButtonAction: Action<Void, Void, Error>?

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

        model.userId = tempUserID
        bindCommands()
        applyUserProfile()
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

        if let tweetDetailViewController = segue.destination as? TWPTweetDetailViewController,
            segue.identifier == "fromUserInfoToTweetDetail" {
            tweetDetailViewController.tempTweetID = selectedTweetID
            tweetDetailViewController.backButtonAction = Action<Void, Void, Error> {
                return SignalProducer<Void, Error> { observer, _ in
                    tweetDetailViewController.dismiss(animated: true, completion: nil)
                    observer.sendCompleted()
                }
            }

        } else if let userListViewController = segue.destination as? TWPUserListViewController,
            segue.identifier == "fromUserInfoToUserList" {
            userListViewController.tempUserID = tempUserID
            userListViewController.backButtonAction = Action<Void, Void, Error> {
                return SignalProducer<Void, Error> { observer, _ in
                    userListViewController.dismiss(animated: true, completion: nil)
                    observer.sendCompleted()
                }
            }
        }
    }

    // MARK: - Binding

    private func bindCommands() {
        if let backButtonAction = backButtonAction {
            backButton.reactive.pressed = CocoaAction(backButtonAction)
        }

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

    // MARK: - Private Methods

    private func showAlert(with error: TWPUserInfoViewModel.UserInfoViewModelError) {
        showAlert(with: "ERROR", message: error.message)
    }

    private func startLoading() {
        loadingView.isHidden = false
        activityIndicatorView.startAnimating()
    }

    private func stopLoading() {
        loadingView.isHidden = true
        activityIndicatorView.stopAnimating()
    }

    private func loadUserInfo() {
        // get user info
        startLoading()
        model.getUserInfo().startWithResult { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.applyUserProfile()
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

    private func applyUserProfile() {
        // set default status
        followButton.isHidden = (model.user?.isSelf == true)

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
            screenNameLabel.text = model.user?.screenNameWithAt
        } else {
            screenNameLabel.text = "no data"
        }

        userIconImageView.sd_setImage(with: model.user?.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: .fromCacheOnly)

        followButton.isSelected = model.user?.following ?? false
    }

    private func changeStatus(of tappedButton: UIButton) {
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
        return model.tweets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TWPUserInfoViewControllerTableViewCell.identifier) as! TWPUserInfoViewControllerTableViewCell
        let tweet = model.tweets[indexPath.row]
        cell.apply(withTweet: tweet)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TWPUserInfoViewControllerTableViewCell.itemHeight
    }
}

extension TWPUserInfoViewController: UITableViewDelegate {
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTweet = model.tweets[indexPath.row]
        selectedTweetID = selectedTweet.tweetId

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
