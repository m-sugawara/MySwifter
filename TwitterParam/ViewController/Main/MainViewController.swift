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

let kMainTableViewCellIdentifier = "MainTableViewCell"

enum MainTableViewButtonType: Int {
    case reply = 1
    case retweet
    case favorite
}

class MainViewController: UIViewController {

    private let model = MainViewModel()
    private var textFieldView: TextFieldView?

    private var scrollBeginingPoint: CGPoint!
    private var isShowFooterView = true

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tweetButton: UIButton!
    @IBOutlet private weak var feedUpdateButton: UIButton!
    @IBOutlet private weak var logoutButton: UIButton!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var footerViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Deinit
    deinit {
        stopObserving()
    }

    // MARK: - Designated Initializer
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        startObserving()
        configureViews()
        bindCommands()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !model.isLoggedIn {
            presentLogin()
        }
    }

    // MARK: - Private Methods
    private func presentLogin() {
        let loginViewController = LoginViewController.makeInstance()
        loginViewController.modalPresentationStyle = .overFullScreen
        present(loginViewController, animated: false, completion: nil)
    }

    private func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    private func stopObserving() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    private func startLoading() {
        loadingView.isHidden = false
        activityIndicatorView.startAnimating()
    }

    private func stopLoading() {
        loadingView.isHidden = true
        activityIndicatorView.stopAnimating()
    }

    private func configureViews() {
        textFieldView = TextFieldView.view()
        textFieldView?.alpha = 0.0
        view.addSubview(textFieldView!)
        textFieldView?.delegate = self

        // bind tableView Delegate
        tableView.dataSource = self
        tableView.delegate = self
    }

    @objc func showTextFieldView(withScreenName screenName:String?) {
        for view in view.subviews {
            if view is TextFieldView {
                continue
            }
            view.isUserInteractionEnabled = false
        }

        var defaultScreenName = ""
        if screenName != "" {
            defaultScreenName = "@" + screenName! + ": "
        }

        textFieldView?.alpha = 0.01
        textFieldView?.textFieldWithLimit.becomeFirstResponder()
        textFieldView?.textFieldWithLimit.text = defaultScreenName
    }

    private func hideTextFieldView() {
        for view in view.subviews {
            if view is TextFieldView {
                continue
            }
            view.isUserInteractionEnabled = true
        }

        // reset selecting Index, when hide textfield view.
        model.selectingIndex = nil

        textFieldView?.alpha = 0.0
        textFieldView?.textFieldWithLimit.resignFirstResponder()
    }

    @objc func keyboardWillShow(notification: Notification) {
        // get frame of keyboard from userinfo
        guard let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let keyboardAnimationDuration = userInfo[
                UIResponder.keyboardAnimationDurationUserInfoKey
                ] as? Double else {
                return
        }

        let margin: CGFloat = 20.0

        let originX = margin
        let originY = keyboardFrame.origin.y
            - textFieldView!.frame.size.height - margin
        let width = view.frame.size.width - (margin * 2)
        let height = textFieldView!.frame.size.height

        textFieldView!.frame = CGRect(
            x: originX, y: originY,
            width: width, height: height)

        // show textfield view with animation.
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.textFieldView?.alpha = 1.0
        }
    }

    private func presentTweetDetail(tweetId: String) {
        let tweetDetailViewController = TweetDetailViewController.makeInstance()
        tweetDetailViewController.tempTweetID = tweetId

        // bind Next ViewController's Commands
        tweetDetailViewController.backButtonAction = Action<Void, Void, Error> {
            return SignalProducer { observer, _ in
                tweetDetailViewController.dismiss(animated: true, completion: nil)
                observer.sendCompleted()
            }
        }

        present(tweetDetailViewController, animated: true, completion: nil)
    }

    // MARK: - Binding
    private func bindCommands() {

        model.eventsSignal.observeValues { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .startToRequest:
                self.startLoading()
            case .failedToRequest(let error):
                self.stopLoading()
                self.showAlert(with: "Error", message: error.message)
            case .loadedFeed, .postedTweet, .postedRetweet, .postedFavorite:
                self.stopLoading()
            }
        }

        logoutButton.reactive.pressed = CocoaAction(Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self, !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }

                let cancelAction: (UIAlertAction?) -> Void = { _ in
                    observer.sendCompleted()
                }
                let yesAction: (UIAlertAction?) -> Void = { [weak self] action in
                    guard let self = self else { return }
                    observer.sendCompleted()
                    self.model.logout()
                    self.presentLogin()
                }
                self.showAlert(
                    with: "ALERT",
                    message: "LOGOUT?",
                    cancelButtonTitle: "NO",
                    cancelTappedAction: cancelAction,
                    otherButtonTitles: ["YES"],
                    otherButtonTappedActions: yesAction
                )
            }
        })
    }

    // MARK: - Actions

    @IBAction func didTapFeedUpdateButton(_ sender: Any) {
        model.updateFeed()
    }
    @IBAction func didTapTweetButton(_ sender: Any) {
        model.postTweet()
    }

    @objc private func tableViewButtonsTouch(sender: UIButton, event: UIEvent) {
        // get indexpath from touch point
        let touch = event.allTouches!.first!
        let point = touch.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)!

        // set selecting Index to ViewModel
        model.selectingIndex = indexPath.row

        let type = MainTableViewButtonType(rawValue: sender.tag)!
        switch type {
        case .reply:
            showTextFieldView(withScreenName: model.selectingTweet?.user?.screenName)

        case .retweet:
            model.postRetweet(with: indexPath.row).startWithResult { [weak self] result in
                switch result {
                case .success:
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.showAlert(with: "ERROR", message: "\(error)")
                }
            }

        case .favorite:
            model.postFavorite(with: indexPath.row).startWithResult { [weak self] result in
                switch result {
                case .success:
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.showAlert(with: "ERROR", message: "\(error)")
                }
            }

        }
    }
}

extension MainViewController: TextFieldViewDelegate {
    func textFieldViewDidTapTweetButton() {
        showTextFieldView(withScreenName: model.selectingTweet?.user?.screenName)
        model.postTweet()
    }

    func textFieldViewDidTapCancelButton() {
        hideTextFieldView()
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.tweets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: kMainTableViewCellIdentifier
            ) as? MainViewControllerTableViewCell else {
            fatalError()
        }

        let tweet = model.tweets[indexPath.row]
        cell.apply(withTweet: tweet)

        // set Cell Actions
        cell.replyButton.tag = MainTableViewButtonType.reply.rawValue
        cell.replyButton.addTarget(
            self,
            action: #selector(tableViewButtonsTouch(sender:event:)),
            for: .touchUpInside
        )

        cell.retweetButton.tag = MainTableViewButtonType.retweet.rawValue
        cell.retweetButton.addTarget(
            self,
            action: #selector(tableViewButtonsTouch(sender:event:)),
            for: .touchUpInside
        )

        cell.favoriteButton.tag = MainTableViewButtonType.favorite.rawValue
        cell.favoriteButton.addTarget(
            self,
            action: #selector(tableViewButtonsTouch(sender:event:)),
            for: .touchUpInside
        )

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130.0
    }

}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTweet = model.tweets[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        presentTweetDetail(tweetId: selectedTweet.tweetId)
    }
}

extension MainViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollBeginingPoint = scrollView.contentOffset
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPoint = scrollView.contentOffset
        if (scrollBeginingPoint.y < currentPoint.y) {
            scrollDown()
        } else {
            scrollUp()
        }
    }

    private func scrollDown() {
        guard !isShowFooterView else { return }

        isShowFooterView = true
        UIView.animate(withDuration: 0.5) {
            self.tweetButton.isHidden = true
            self.footerViewHeightConstraint.constant = 0.0
            self.view.layoutIfNeeded()
        }
    }

    private func scrollUp() {
        guard isShowFooterView else { return }
        isShowFooterView = false
        UIView.animate(withDuration: 0.5) {
            self.footerViewHeightConstraint.constant = 70.0
            self.tweetButton.isHidden = false
            self.view.layoutIfNeeded()
        }
    }
}
