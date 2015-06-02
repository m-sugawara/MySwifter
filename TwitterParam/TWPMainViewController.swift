//
//  MainViewController.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit


class TWPMainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let model: TWPMainViewModel = TWPMainViewModel()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var oauthButton: UIButton!
    @IBOutlet weak var accountButton: UIButton!
    
    // test
    var items = ["Item 1", "Item 2", "Item 3", "Item 4"]
    
    // MARK: - Disignated Initializer
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.bindCommands();
        
        // bind tableView Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Binding
    func bindCommands() {
        // bind tapButton to the RACCommand
        self.oauthButton.rac_command = self.model.oauthButtonCommand
        
        // bind ViewModel's parameter
        self.model.rac_valuesForKeyPath("tapCount", observer: self).subscribeNext { (tapCount) -> Void in
            println(tapCount)
        }
        self.model.rac_valuesForKeyPath("tweets", observer: self).subscribeNext { (tweets) -> Void in
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.model.tweets.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "Cell"
        var cell:TWPMainViewControllerTableCell! = tableView.dequeueReusableCellWithIdentifier("Cell") as? TWPMainViewControllerTableCell
        if cell == nil {
            self.tableView.registerNib(UINib(nibName: "TWPMainViewControllerTableCell", bundle: nil), forCellReuseIdentifier: identifier)
            cell = self.tableView.dequeueReusableCellWithIdentifier(identifier) as? TWPMainViewControllerTableCell
        }
        var tweet:TWPTweet = self.model.tweets[indexPath.row] as! TWPTweet
        cell.iconImageView.sd_setImageWithURL(tweet.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: SDWebImageOptions.CacheMemoryOnly)
        cell.tweetTextLabel.text = tweet.text
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70.0
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }


}

