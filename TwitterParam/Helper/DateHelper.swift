//
//  DateHelper.swift
//  TwitterParam
//
//  Created by M_Sugawara on 2020/02/29.
//  Copyright © 2020 sugawar. All rights reserved.
//

import Foundation

class DateHelper {

    private let formatter: DateFormatter

    init() {
        formatter = DateFormatter()
    }

    func dateToString(date: Date, format: String?, timeZone: TimeZone? = TimeZone.current) -> String {
        formatter.timeZone = timeZone
        formatter.dateFormat = format

        return formatter.string(from: date)
    }

    func formattedDiffText(date: Date, since otherDate: Date = Date()) -> String {
        var minInterval = 0
        var hourInterval = 0
        var dayInterval = 0
        let interval = abs(Int(date.timeIntervalSince(otherDate)))
        if (interval >= 86400) {
            dayInterval = interval / 86400
            return String(dayInterval) + " days"
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
