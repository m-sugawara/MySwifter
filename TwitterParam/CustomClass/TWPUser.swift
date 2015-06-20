//
//  TWPUser.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2015/06/20.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import UIKit

class TWPUser:NSObject {
    var userID: String?
    var name: String?
    var screen_name: String?
    var profileImageUrl: NSURL?
    
    override init() {
        super.init()
    }
    
    init(userID: String?, name: String?, screen_name: String?, profileImageUrl: String?) {
        self.userID = userID
        self.name = name
        self.screen_name = screen_name
        self.profileImageUrl = NSURL(string: profileImageUrl!)
    }
    
    var profileImageUrlString : String? {
        return profileImageUrl?.absoluteString
    }
    
}