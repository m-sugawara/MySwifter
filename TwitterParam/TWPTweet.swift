//
//  TWPTweet.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/02.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

class TWPTweet {
    var text: String?
    var profileImageUrl: NSURL?
    
    init(text: String?, profileImageUrl: String?) {
        self.text = text
        self.profileImageUrl = NSURL(string: profileImageUrl!)
    }
    
    var profileImageUrlString : String? {
        return profileImageUrl?.absoluteString
    }
    
}