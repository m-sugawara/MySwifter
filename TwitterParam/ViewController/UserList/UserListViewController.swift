//
//  UserListViewController.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/28.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import ReactiveSwift
import SDWebImage

class UserListViewController: UIViewController {

    private let model = UserListViewModel()

    // use move from userInfo etc
    var tempUserID: String?
    var backButtonAction: Action<Void, Void, Error>?

    @IBOutlet private weak var userListTableView: UITableView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        bindActions()

        // first, get follow/follower list
        startLoading()
        model.getUserList(with: tempUserID!).startWithResult { [weak self] result in
            switch result {
            case .success:
                self?.stopLoading()
                self?.userListTableView.reloadData()
            case .failure(let error):
                print("error: \(error)")
                self?.showAlert(with: "ERROR", message: "failed to get user list")
            }
        }
    }

    // MARK: - Private Methods
    func startLoading() {
        loadingView.isHidden = false
        activityIndicatorView.startAnimating()
    }

    func stopLoading() {
        loadingView.isHidden = true
        activityIndicatorView.stopAnimating()
    }

    private func presentUserInfo(userId: String) {
        let userInfoViewController = UserInfoViewController.makeInstance()
        userInfoViewController.tempUserID = userId

        // bind Next ViewController's Commands
        userInfoViewController.backButtonAction = Action<Void, Void, Error> {
            return SignalProducer<Void, Error> { observer, _ in
                userInfoViewController.dismiss(animated: true, completion: nil)
                observer.sendCompleted()
            }
        }
        present(userInfoViewController, animated: true, completion: nil)
    }

    // MARK: - Binding
    private func bindActions() {
        if let backButtonAction = backButtonAction {
            backButton.reactive.pressed = CocoaAction(backButtonAction)
        }
    }
}

extension UserListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "Cell") as? UserListTableViewCell else {
            fatalError()
        }

        let user = model.user(at: indexPath.row)
        cell.apply(with: user)

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.userList.count
    }
}

extension UserListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UserListTableViewCell.itemHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedUser = model.user(at: indexPath.row) else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        presentUserInfo(userId: selectedUser.userId)
    }
}
