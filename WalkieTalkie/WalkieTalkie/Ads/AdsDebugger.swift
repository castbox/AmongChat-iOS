////
////  AdsDebugger.swift
////  Scanner
////
////  Created by 江嘉睿 on 2020/3/31.
////  Copyright © 2020 江嘉睿. All rights reserved.
////
//
//import Foundation
//
//enum AdFormat: String {
//    case native = "native"
//    case banner = "banner"
//    case interstitial = "interstital"
//}
//
//enum AdEvent: String {
//    case request = "request"
//    case awsBidSuccess = "awsBidSuccess"
//    case awsBidFail = "awsBidFail"
//    case load = "load"
//    case nofill = "nofill"
//    case renderFail = "renderFail"
//    case rendered = "rendered"
//    case impl = "impl"
//    case click = "click"
//}
//
//extension Notification.Name {
//    static var adEvent: NSNotification.Name {
//        return  .init("scanner_ad_event")
//    }
//}
//
//struct AdEventInfo {
//    let format: AdFormat
//    let event: AdEvent
//    let eventTime: Date
//    let requestTime: Date
//    
//    static func makeBannerEventInfo(_ event: AdEvent) -> AdEventInfo {
//        let date = Date()
//        return AdEventInfo(format: .banner, event: event, eventTime: date, requestTime: date)
//    }
//        
//    func basicDescription() -> String {
//        var description = "\(format) event:\(event)"
//        switch (format, event) {
//        case (.native, .request):
//            ()
//        case (.native, _):
//            let intervalInSeconds = String(format: "%.3f", eventTime.timeIntervalSince(requestTime))
//            description += " \(intervalInSeconds) seconds since request"
//        default:
//            ()
//        }
//        return description
//    }
//    
//    func stringWithShortDate() -> String {
//        let date = shortDateFormatter.string(from: eventTime)
//        return "\(date) \(basicDescription())"
//    }
//}
