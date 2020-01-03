//
//  UserInfoViewControllerTableViewCell.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/19.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import TTTAttributedLabel

class UserInfoViewControllerTableViewCell: UITableViewCell {

    static let identifier = "UserInfoTableViewCell"
    static let itemHeight: CGFloat = 60.0

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var tweetTextLabel: TTTAttributedLabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        tweetTextLabel.delegate = self
    }

    func apply(withTweet tweet: Tweet) {
        iconImageView.sd_setImage(
            with: tweet.user?.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: .fromCacheOnly)
        tweetTextLabel.text = tweet.text
        tweetTextLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
    }
}

extension UserInfoViewControllerTableViewCell: TTTAttributedLabelDelegate {
    // MARK: - TTTAttributedLabelDelegate
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.open(url)
    }
}
