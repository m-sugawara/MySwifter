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

let kTWPUserInfoTableViewCellIdentifier = "UserInfoTableViewCell";

enum TWPUserListType {
    case followList
    case followerList
}

class TWPUserInfoViewController: UIViewController {
    let model = TWPUserInfoViewModel()
    
    var selectingUserList: TWPUserListType?
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
        
        self.bindCommands()
        
        // view did show for the firsttime, load user's timeline
        if self.tempUserID != nil {
            // TODO: bad solution
            self.model.userId = self.tempUserID
            
            // set default status
            if self.model.userId == TWPUserHelper.currentUserID() {
                self.followButton.isHidden = true
            }
            
            // get user info
            self.startLoading()
            self.model.getUserInfoSignalProducer().startWithResult { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.setUserProfile()
                    self.model.getUserTimelineSignalProducer().startWithResult { [weak self] result in
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
            self.showAlert(with: "ERROR!", message: "user not found!", cancelButtonTitle: "Back", cancelTappedAction: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            return
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        let action = Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { observer, lifetime in
                self.dismiss(animated: true, completion: nil)
                observer.sendCompleted()
            }
        }
        if segue.identifier == "fromUserInfoToTweetDetail" {
            let tweetDetailViewController = segue.destination as! TWPTweetDetailViewController
            
            tweetDetailViewController.tempTweetID = self.selectedTweetID
            tweetDetailViewController.backButtonCommand = CocoaAction(action)
        }
        else if segue.identifier == "fromUserInfoToUserList" {
            let userListViewController = segue.destination as! TWPUserListViewController
            userListViewController.tempUserID = self.tempUserID
            userListViewController.backButtonAction = CocoaAction(action)
        }
    }
    
    // MARK: - Binding
    
    func bindCommands() {
        self.backButton.reactive.pressed = self.backButtonAction
        
        // follow list button
        followListButton.reactive.pressed = CocoaAction<UIButton>(Action<Void, Void, Error>{
            return SignalProducer<Void, Error> { observer, lifetime in
                guard !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }
                self.selectingUserList = TWPUserListType.followList
                self.performSegue(withIdentifier: "fromUserInfoToUserList", sender: nil)
                observer.sendCompleted()
            }
        })

        // follower list button
        followerListButton.reactive.pressed = CocoaAction<UIButton>(Action<Void, Void, Error>{
            return SignalProducer<Void, Error> { observer, lifetime in
                guard !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }
                self.selectingUserList = TWPUserListType.followerList
                self.performSegue(withIdentifier: "fromUserInfoToUserList", sender: nil)
                observer.sendCompleted()
            }
        })
        
        // follow button
        followButton.reactive.pressed = model.followButtonCommand
//        followButton.isSelected <~ model.user!.following
        // TODO: handling error
//        self.followButton.rac_command.errors.subscribeNext { [weak self] (error) -> Void in
//            print("user follow error:\(error)")
//            self!.showAlertWithTitle("ERROR", message:error.localizedDescription)
//        }
        
        // SelectListButtons
        tweetListButton.reactive.pressed = CocoaAction(Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self else { return }
                // get users timeline
                self.startLoading()
                self.model.getUserTimelineSignalProducer().startWithResult { [weak self] result in
                    guard let self = self else { return }

                    self.stopLoading()

                    switch result {
                    case .success:
                        self.tableView.reloadData()
//                        self.changeListButtonsStatusWithTappedButton(input as! UIButton)

                    case .failure:
                        self.showAlert(with: "ERROR!", message: "failed to get user timeline.")
                    }
                    observer.sendCompleted()
                }
            }
        })

        // ImageListButton
        imageListButton.reactive.pressed = CocoaAction(Action {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self else { return }
                self.startLoading()
                self.model.getUserImageListSignalProducer().startWithResult { [weak self] result in
                    guard let self = self else { return }

                    self.stopLoading()

                    switch result {
                    case .success:
                        self.tableView.reloadData()
                        //                        self.changeListButtonsStatusWithTappedButton(input as! UIButton)

                    case .failure:
                        self.showAlert(with: "ERROR!", message: "failed to get user image list.")
                    }
                    observer.sendCompleted()
                }
            }
        })

        // FavoriteListButton
        favoriteListButton.reactive.pressed = CocoaAction(Action {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self else { return }
                self.startLoading()
                self.model.getUserFavoritesListSignalProducer().startWithResult { [weak self] result in
                    guard let self = self else { return }

                    self.stopLoading()

                    switch result {
                    case .success:
                        self.tableView.reloadData()
                        //                        self.changeListButtonsStatusWithTappedButton(input as! UIButton)

                    case .failure:
                        self.showAlert(with: "ERROR!", message: "failed to get user image list.")
                    }
                    observer.sendCompleted()
                }
            }
        })
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
        self.userNameLabel.text = self.model.user?.name
        
        self.followListButton.setTitle(String(self.model.user!.friendsCount!) + " follows",
                                       for: .normal)
        self.followerListButton.setTitle(String(self.model.user!.followersCount!) + " followers",
            for: .normal)
        
        
        if self.model.user?.screenName != nil {
            self.screenNameLabel.text = self.model.user?.screenNameWithAt
        }
        else {
            self.screenNameLabel.text = "no data"
        }
        
        self.userIconImageView.sd_setImage(with: self.model.user?.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: .fromCacheOnly)
        
        self.followButton.isSelected = self.model.user?.following ?? false
    }
    
    func changeListButtonsStatusWithTappedButton(tappedButton: UIButton) {
        let listButtons: Array<UIButton> = [self.tweetListButton, self.imageListButton, self.favoriteListButton]
        
        for listButton in listButtons {
            if listButton == tappedButton {
                listButton.isSelected = true
                listButton.backgroundColor = .lightGray
            }
            else {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: kTWPUserInfoTableViewCellIdentifier) as! TWPUserInfoViewControllerTableViewCell
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
        self.selectedTweetID = selectedTweet.tweetID

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
