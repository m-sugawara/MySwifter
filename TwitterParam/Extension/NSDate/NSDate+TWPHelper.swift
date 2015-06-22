//
//  NSDate+TWPHelper.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/22.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

extension NSDate {
    func stringWithFormat(format: String?, localeIdentifier: String? = "ja") -> String {
        var formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: localeIdentifier!)
        formatter.dateFormat = format
        
        return formatter.stringFromDate(self)
    }
    
    func stringForTimeIntervalSinceCreated() -> String {
        return stringForTimeIntervalSinceCreated(nowDate: NSDate())
    }
    
    func stringForTimeIntervalSinceCreated(#nowDate: NSDate) -> String {
        var MinInterval  :Int = 0
        var HourInterval :Int = 0
        var DayInterval  :Int = 0
        var DayModules   :Int = 0
        let interval = abs(Int(self.timeIntervalSinceDate(nowDate)))
        if (interval >= 86400) {
            DayInterval = interval / 86400
            DayModules = interval % 86400
            if (DayModules != 0) {
                if (DayModules >= 3600) {
                    // HourInterval=DayModules/3660;
                    return String(DayInterval) + " days"
                }
                else {
                    if (DayModules >= 60) {
                        // MinInterval=DayModules/60;
                        return String(DayInterval) + " days"
                    }
                    else {
                        return String(DayInterval) + " days"
                    }
                }
            }
            else {
                return String(DayInterval) + " days"
            }
        }
        else {
            if (interval >= 3600) {
                HourInterval = interval / 3600
                return String(HourInterval) + " hours"
            }
            else if (interval >= 60) {
                MinInterval = interval / 60
                return String(MinInterval) + " minutes"
            }
            else {
                return String(interval) + " sec"
            }
        }

    }
}