//
//  String+TWPHelper.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/22.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

extension String {
    func dateWithFormat(format: String?, localeIdentifier: String? = "ja") -> NSDate {
        var formatter = DateFormatter()
        formatter.locale = NSLocale(localeIdentifier: localeIdentifier!)
        formatter.dateFormat = format
        
        return formatter.dateFromString(self)!
    }
}
