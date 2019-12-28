//
//  TWPUserInfoViewControllerTableViewCell.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/19.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import TTTAttributedLabel

class TWPUserInfoViewControllerTableViewCell: UITableViewCell {

    static let identifier = "UserInfoTableViewCell"
    static let itemHeight: CGFloat = 60.0

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var tweetTextLabel: TTTAttributedLabel!

    func apply(withTweet tweet: TWPTweet) {
        iconImageView.sd_setImage(
            with: tweet.user?.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: .fromCacheOnly)
        tweetTextLabel.text = tweet.text
        tweetTextLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
    }
}
