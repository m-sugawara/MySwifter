//
//  TWPTweet.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit
import SwifteriOS

class TWPTweet:NSObject {
    var tweetID: String
    var text: String?
    var user: TWPUser?
    
    init(tweetID: String, text: String?, user: TWPUser?) {
        self.tweetID = tweetID
        self.text = text
        self.user = user
    }
    
}