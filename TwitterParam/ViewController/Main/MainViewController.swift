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
import Swinject

class MainViewController: UIViewController {

    var container: Container!
    var model: MainViewModel!

    private var scrollBeginingPoint: CGPoint!
    private var isShowingFooterView = true

    private var textFieldView: TextFieldView?

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

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        startObserving()
        configureViews()
        bindCommands()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard model.isLoggedIn else {
            presentLogin()
            return
        }

        model.updateFeed()
    }

    // MARK: - Private Methods
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
        view.addSubview(textFieldView!)
        textFieldView?.delegate = self

        // bind tableView Delegate
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func showTextFieldView(withScreenName screenName: String?) {
        for view in view.subviews {
            if view is TextFieldView {
                continue
            }
            view.isUserInteractionEnabled = false
        }

        let text = model.defaultText(withScreenName: screenName)
        textFieldView?.activate(withText: text)
    }

    private func hideTextFieldView() {
        for view in view.subviews {
            if view is TextFieldView {
                continue
            }
            view.isUserInteractionEnabled = true
        }

        textFieldView?.deactivate()
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

    private func presentLogin() {
        let loginViewController = container.resolve(LoginViewController.self)!
        loginViewController.modalPresentationStyle = .overFullScreen
        present(loginViewController, animated: false, completion: nil)
    }

    private func presentTweetDetail(tweetId: String) {
        let tweetDetailViewController = container.resolve(TweetDetailViewController.self)!
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
    }

    // MARK: - Actions

    @IBAction func didTapFeedUpdateButton(_ sender: Any) {
        model.updateFeed()
    }
    @IBAction func didTapTweetButton(_ sender: Any) {
        model.postTweet()
    }

    @IBAction func didTapLogoutButton(_ sender: Any) {
        let yesAction: (UIAlertAction?) -> Void = { [weak self] action in
            guard let self = self else { return }
            self.model.logout()
            self.presentLogin()
        }
        showAlert(
            with: "ALERT",
            message: "LOGOUT?",
            cancelButtonTitle: "NO",
            otherButtonTitles: ["YES"],
            otherButtonTappedActions: yesAction
        )
    }
}

extension MainViewController: TextFieldViewDelegate {
    func textFieldViewDidTapTweetButton() {
        hideTextFieldView()
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
            withIdentifier: FeedTableViewCell.identifier
            ) as? FeedTableViewCell else {
            fatalError()
        }

        let tweet = model.tweets[indexPath.row]
        cell.apply(withTweet: tweet, index: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130.0
    }
}

extension MainViewController: FeedTableViewCellDelegate {
    func feedTableViewCellDidTapReply(withIndex index: Int) {
        let selectedTweet = model.tweets[index]
        showTextFieldView(withScreenName: selectedTweet.user?.screenName)
        model.postTweet(withIndex: index)
    }

    func feedTableViewCellDidTapRetweet(withIndex index: Int) {
        model.postRetweet(withIndex: index)
    }

    func feedTableViewCellDidTapFavorite(withIndex index: Int) {
        model.postFavorite(withIndex: index)
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
            hideFooterView()
        } else {
            showFooterView()
        }
    }

    private func hideFooterView() {
        guard isShowingFooterView else { return }

        isShowingFooterView = false
        UIView.animate(withDuration: 0.5) {
            self.tweetButton.isHidden = true
            self.footerViewHeightConstraint.constant = 0.0
            self.view.layoutIfNeeded()
        }
    }

    private func showFooterView() {
        guard !isShowingFooterView else { return }

        isShowingFooterView = true
        UIView.animate(withDuration: 0.5) {
            self.footerViewHeightConstraint.constant = 70.0
            self.tweetButton.isHidden = false
            self.view.layoutIfNeeded()
        }
    }
}
