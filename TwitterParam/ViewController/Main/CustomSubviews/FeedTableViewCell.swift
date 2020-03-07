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

protocol FeedTableViewCellDelegate: class {
    func feedTableViewCellDidTapReply(withIndex index: Int)
    func feedTableViewCellDidTapRetweet(withIndex index: Int)
    func feedTableViewCellDidTapFavorite(withIndex index: Int)
}

class FeedTableViewCell: UITableViewCell {

    static let identifier = "FeedTableViewCell"

    weak var delegate: FeedTableViewCellDelegate?

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

    private var index: Int = -1
    private let dateHelper = DateHelper()

    // MARK: Designated Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        iconImageView.image = nil

        tweetTextLabel.text = nil
        userNameLabel.text = nil
        screenNameLabel.text = nil
        retweetCountLabel.text = nil
        favoriteCountLabel.text = nil
        timeLabel.text = nil

        retweetButton.isSelected = false
        favoriteButton.isSelected = false
    }

    func apply(withTweet tweet: Tweet, index: Int) {
        self.index = index

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

        if let createdAt = tweet.createdAt {
            timeLabel.text = dateHelper.formattedDiffText(date: createdAt)
        }
    }

    @IBAction func didTapReplyButton(_ sender: Any) {
        delegate?.feedTableViewCellDidTapReply(withIndex: index)
    }

    @IBAction func didTapRetweetButton(_ sender: Any) {
        delegate?.feedTableViewCellDidTapRetweet(withIndex: index)
    }

    @IBAction func didTapFavoriteButton(_ sender: Any) {
        delegate?.feedTableViewCellDidTapFavorite(withIndex: index)
    }
}
