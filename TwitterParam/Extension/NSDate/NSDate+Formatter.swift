//
//  NSDate+Helper.swift
//  TwitterParam
//
//  Created by m_sugawara on 2015/06/22.
//  Copyright (c) 2015年 sugawar. All rights reserved.
//

import Foundation

extension Date {
    func stringWithFormat(format: String?, localeIdentifier: String = "ja") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateFormat = format

        return formatter.string(from: self)
    }

    func stringForTimeIntervalSinceCreated() -> String {
        return stringForTimeIntervalSinceCreated(nowDate: Date())
    }

    func stringForTimeIntervalSinceCreated(nowDate: Date) -> String {
        var minInterval = 0
        var hourInterval = 0
        var dayInterval = 0
        var dayModules = 0
        let interval = abs(Int(timeIntervalSince(nowDate)))
        if (interval >= 86400) {
            dayInterval = interval / 86400
            dayModules = interval % 86400
            if (dayModules != 0) {
                if (dayModules >= 3600) {
                    // HourInterval=DayModules/3660;
                    return String(dayInterval) + " days"
                } else {
                    if (dayModules >= 60) {
                        // MinInterval=DayModules/60;
                        return String(dayInterval) + " days"
                    } else {
                        return String(dayInterval) + " days"
                    }
                }
            } else {
                return String(dayInterval) + " days"
            }
        } else {
            if (interval >= 3600) {
                hourInterval = interval / 3600
                return String(hourInterval) + " hours"
            } else if (interval >= 60) {
                minInterval = interval / 60
                return String(minInterval) + " minutes"
            } else {
                return String(interval) + " sec"
            }
        }

    }
}
