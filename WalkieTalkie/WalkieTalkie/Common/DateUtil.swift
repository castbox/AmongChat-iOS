//
//  DateUtil.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/8/29.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation

fileprivate let minutesPerDay: Int = 3600 * 24

class ServerFormatter {
    private let standardFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    
    private let dateFormat = "yyyy-MM-dd"
    
    private let serverFormatter: DateFormatter
    
    private let abbrFormatter: DateFormatter
    
    private let shortDateFormatter: DateFormatter
    
    private let mediumDateFormatter: DateFormatter
    
    init() {
        serverFormatter = DateFormatter()
        serverFormatter.dateFormat = standardFormat
        serverFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        abbrFormatter = DateFormatter()
        abbrFormatter.timeZone = TimeZone.current
//        abbrFormatter.dateFormat = "h:mma"
        abbrFormatter.dateStyle = .none
        abbrFormatter.timeStyle = .short
        
        mediumDateFormatter = DateFormatter()
        mediumDateFormatter.timeZone = TimeZone.current
        mediumDateFormatter.dateStyle = .short
        mediumDateFormatter.timeStyle = .short

        
        shortDateFormatter = DateFormatter()
        shortDateFormatter.timeZone = TimeZone.current
        shortDateFormatter.dateFormat = dateFormat
    }
    
    func serverTimeToLocal(_ serverTime: String) -> Date? {
        return serverFormatter.date(from: serverTime)
    }
    
    func serverTimeToAbbrLocal(_ serverTime: String) -> String? {
        guard let dt = serverFormatter.date(from: serverTime) else {
            return nil
        }
        return abbrFormatter.string(from: dt)
    }
    
    func daysSince(eventDate: Date, current: Date) -> Int {
        let startOfCurrent = shortDateFormatter.date(from: shortDateFormatter.string(from: current))!
        let delta = startOfCurrent.timeIntervalSince(eventDate) + TimeInterval(minutesPerDay)
        let days = Int(Int(delta) / minutesPerDay)
        return days >= 0 ? days : 0
    }
}

extension Date {
    func isToday() -> Bool {
        let today = Date()
        let startOfToday = dateOnlyFormatter.date(from: dateOnlyFormatter.string(from: today))!
        let delta = startOfToday.timeIntervalSince(self) + TimeInterval(minutesPerDay)
        let days = Int(Int(delta) / minutesPerDay)
        return days <= 0
    }
}

let standardServerTimeFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.timeZone = TimeZone(abbreviation: "UTC")
    fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    return fmt
}()

let shortDateFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.timeZone = TimeZone.current
//    fmt.dateFormat = "h:mma"
    fmt.dateStyle = .none
    fmt.timeStyle = .short
    return fmt
}()

let mediumDateFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.timeZone = TimeZone.current
    fmt.dateStyle = .short
    fmt.timeStyle = .short
    return fmt
}()

let dateOnlyFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.timeZone = TimeZone.current
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt
}()


//func localToUTC(date:String) -> String {
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = "h:mm a"
//    dateFormatter.calendar = NSCalendar.current
//    dateFormatter.timeZone = TimeZone.current
//
//    let dt = dateFormatter.date(from: date)
//    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//    dateFormatter.dateFormat = "H:mm:ss"
//
//    return dateFormatter.string(from: dt!)
//}
//
//private let serverFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
//
//func UTCToLocal(date:String, format: String = serverFormat) -> (Int, String) {
//    let dateFormatter = DateFormatter()
//    dateFormatter.dateFormat = format
//    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//
//    let dt = dateFormatter.date(from: date)
//    dateFormatter.timeZone = TimeZone.current
//    dateFormatter.dateFormat = "h:mm a"
//
//    let now = Date()
//    let delta = Int(now.timeIntervalSince(dt!) / 3600 / 24)
//    return (delta, dateFormatter.string(from: dt!))
//}
