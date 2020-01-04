//
//  MainViewControllerTableViewCell.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/01.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

import TTTAttributedLabel
import SDWebImage

class MainViewControllerTableViewCell: UITableViewCell {

    static let identifier = "MainTableViewCell"

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var tweetTextLabel: TTTAttributedLabel!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var screenNameLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var retweetCountLabel: UILabel!
    @IBOutlet private weak var favoriteCountLabel: UILabel!

    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var retweetButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!

    // MARK: Designated Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func apply(withTweet tweet: Tweet) {
        iconImageView.sd_setImage(
            with: tweet.user!.profileImageUrl,
            placeholderImage: UIImage(named: "Main_TableViewCellIcon"),
            options: .fromCacheOnly)

        tweetTextLabel.text = tweet.text
        tweetTextLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        userNameLabel.text = tweet.user?.name
        screenNameLabel.text = tweet.user?.screenNameWithAt
        retweetCountLabel.text = String(tweet.retweetCount)
        favoriteCountLabel.text = String(tweet.favoriteCount)

        retweetButton.isSelected = tweet.retweeted
        favoriteButton.isSelected = tweet.favorited

        timeLabel.text = tweet.createdAt?.stringForTimeIntervalSinceCreated()
    }

}
