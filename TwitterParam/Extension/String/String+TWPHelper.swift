//
//  String+TWPHelper.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/22.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

extension String {
    func date(with format: String?, localeIdentifier: String? = "ja") -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier!)
        formatter.dateFormat = format
        
        return formatter.date(from: self)!
    }
}
