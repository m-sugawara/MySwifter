//
//  TWPUserListViewController.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/28.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import ReactiveSwift
import SDWebImage

class TWPUserListViewController: UIViewController {

    private let model = TWPUserListViewModel()

    // use move from userInfo etc
    var tempUserID: String?
    var backButtonAction: CocoaAction<UIButton>?
    // use move to userInfo
    var selectedUserID: String?

    @IBOutlet private weak var userListTableView: UITableView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.model.selectingUserID = self.tempUserID

        // Do any additional setup after loading the view.
        self.bindCommands()

        // first, get follow/follower list
        self.startLoading()
        self.model.getUserList().startWithResult { [weak self] result in
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        // UserInfoViewController
        if let userInfoViewController = segue.destination as? TWPUserInfoViewController,
            segue.identifier == "fromUserListToUserInfo" {

            userInfoViewController.tempUserID = self.selectedUserID

            // bind Next ViewController's Commands
            userInfoViewController.backButtonAction = CocoaAction(Action<Void, Void, Error> {
                return SignalProducer<Void, Error> { [weak self] observer, _ in
                    self?.dismiss(animated: true, completion: nil)
                    observer.sendCompleted()
                }
            })
        }
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

    // MARK: - Binding
    func bindCommands() {
        self.backButton.reactive.pressed = backButtonAction
    }
}

extension TWPUserListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "Cell") as? TWPUserListTableViewCell else {
            fatalError()
        }

        let user = self.model.userList[indexPath.row]
        cell.nameLabel.text = user.name
        cell.screenNameLabel.text = user.screenNameWithAt
        cell.userImageView.sd_setImage(
            with: user.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: .fromCacheOnly
        )

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.userList.count
    }
}

extension TWPUserListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = self.model.userList[indexPath.row]
        selectedUserID = selectedUser.userId

        tableView.deselectRow(at: indexPath, animated: true)

        performSegue(withIdentifier: "fromUserListToUserInfo", sender: nil)
    }
}
