//
//  TWPUserListViewController.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/28.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import ReactiveCocoa
import SDWebImage

class TWPUserListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let model = TWPUserListViewModel()

    // use move from userInfo etc
    var tempUserID: String?
    var backButtonCommand: CocoaAction?
    // use move to userInfo
    var selectedUserID: String?
    
    @IBOutlet weak var userListTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.model.selectingUserID = self.tempUserID

        // Do any additional setup after loading the view.
        self.bindCommands()
        
        // first, get follow/follower list
        self.startLoading()
        self.model.getUserList()?.subscribeNext({ [weak self] (next) -> Void in
            
        }, error: { (error) -> Void in
            print("\(error)")
        }, completed: { () -> Void in
            self.userListTableView.reloadData()
            self.stopLoading()
            self.showAlertWithTitle("SUCCESS", message: "success")
        })
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        // UserInfoViewController
        if segue.identifier == "fromUserListToUserInfo" {
            var userInfoViewController:TWPUserInfoViewController = segue.destinationViewController as! TWPUserInfoViewController
            
            // TODO: bad solution
            userInfoViewController.tempUserID = self.selectedUserID
            
            // bind Next ViewController's Commands
            userInfoViewController.backButtonCommand = RACCommand(signalBlock: { (input) -> RACSignal! in
                return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
                    subscriber.sendCompleted()
                    
                    return RACDisposable(block: { () -> Void in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                })
            })
            
        }
    }

    // MARK: - Private Methods
    func startLoading() {
        self.loadingView.hidden = false
        self.activityIndicatorView.startAnimating()
    }
    
    func stopLoading() {
        self.loadingView.hidden = true
        self.activityIndicatorView.stopAnimating()
    }
    
    // MARK: - MemoryManagement
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Binding
    func bindCommands() {
        self.backButton.rac_command = backButtonCommand
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! TWPUserListTableViewCell
        
        var user = self.model.userList[indexPath.row]
        cell.nameLabel.text = user.name
        cell.screenNameLabel.text = user.screenNameWithAt
        
        cell.userImageView.sd_setImageWithURL(user.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: SDWebImageOptions.CacheMemoryOnly)
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.userList.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedUser: TWPUser = self.model.userList[indexPath.row] as TWPUser;
        self.selectedUserID = selectedUser.userID
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        self.performSegueWithIdentifier("fromUserListToUserInfo", sender: nil)
    }


}
