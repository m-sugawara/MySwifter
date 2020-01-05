//
//  UserListTableViewCell.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/28.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class UserListTableViewCell: UITableViewCell {

    static let itemHeight: CGFloat = 70

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var screenNameLabel: UILabel!
    @IBOutlet private weak var userImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        screenNameLabel.text = nil
        userImageView.image = nil
    }

    func apply(with user: User?) {
        guard let user = user else { return }
        nameLabel.text = user.name
        screenNameLabel.text = user.screenNameWithAt
        userImageView.sd_setImage(
            with: user.profileImageUrl,
            placeholderImage: UIImage(named:"Main_TableViewCellIcon"),
            options: .fromCacheOnly
        )
    }
}
