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
let kTextFieldMaxLength = 140
let kTextFieldMarginWidth: CGFloat = 20.0
let kTextFieldMarginHeight: CGFloat = 20.0

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

    // MARK: - Disignated Initializer
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        startObserving()
        configureViews()
        bindCommands()

        // bind tableView Delegate
        tableView.dataSource = self
        tableView.delegate = self

        // first, load current user's home timeline
        startLoading()
        model.feedUpdate.startWithResult { [weak self] result in
            switch result {
            case .success:
                self?.stopLoading()
            case .failure(let error):
                self?.stopLoading()
                self?.showAlert(with: "ERROR", message: error.localizedDescription)
            }
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
        loadingView.isHidden = false
        activityIndicatorView.startAnimating()
    }

    func stopLoading() {
        loadingView.isHidden = true
        activityIndicatorView.stopAnimating()
    }

    func configureViews() {
        textFieldView = TextFieldView.view(
            withMaxLength: kTextFieldMaxLength,
            delegate: self
        )
        textFieldView?.alpha = 0.0
        view.addSubview(textFieldView!)
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
        textFieldView?.textFieldWithLimit.limitLabel.text = String(kTextFieldMaxLength)
    }

    func hideTextFieldView() {
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

        let textFieldViewOriginX = kTextFieldMarginWidth
        let textFieldViewOriginY = keyboardFrame.origin.y
            - textFieldView!.frame.size.height - kTextFieldMarginHeight
        let textFieldViewSizeWidth = view.frame.size.width - (kTextFieldMarginWidth * 2)
        let textFieldViewSizeHeight = textFieldView!.frame.size.height

        textFieldView!.frame = CGRect(
            x: textFieldViewOriginX,
            y: textFieldViewOriginY,
            width: textFieldViewSizeWidth,
            height: textFieldViewSizeHeight)

        // show textfield view with animation.
        UIView.animate(withDuration: keyboardAnimationDuration, animations: { () -> Void in
            self.textFieldView?.alpha = 1.0
        })
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
    func bindCommands() {

        // bind Button to the RACCommand
        tweetButton.reactive.pressed = CocoaAction(Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { [weak self] observer, lifetime in
                guard let self = self, !lifetime.hasEnded else {
                    observer.sendInterrupted()
                    return
                }
                self.showTextFieldView(withScreenName: self.model.selectingTweet?.user?.screenName)
                observer.sendCompleted()
            }
        })

        feedUpdateButton.reactive.pressed = CocoaAction(model.feedUpdateButtonAction)
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
                    // if selected YES, try to logout and dismissViewController
                    TwitterAPI.shared.logout()
                    observer.sendCompleted()
                    self?.dismiss(animated: true, completion: nil)
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

        // TextFieldView Commands
        textFieldView?.cancelButton.reactive.pressed = CocoaAction(
            Action(execute: { _ -> SignalProducer<Void, Error> in
            return SignalProducer<Void, Error> { observer, _ in
                self.hideTextFieldView()
                observer.sendCompleted()
            }
        }))

        textFieldView?.tweetButton.reactive.pressed = CocoaAction(model.tweetButtonAction)
        feedUpdateButton.reactive.pressed = CocoaAction(model.feedUpdateButtonAction)
        tweetButton.reactive.pressed = CocoaAction(model.tweetButtonAction)
    }

    // MARK: - Actions
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
extension MainViewController: UITextFieldWithLimitDelegate {

}
extension MainViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url)
    }
}
