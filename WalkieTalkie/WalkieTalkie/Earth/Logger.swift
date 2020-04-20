//
//  Logger.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import Crashlytics

class Logger { }

extension Logger {
    
    //    struct PageShow {
    
    enum EventName: String {
        case screen
        case enter_room
    }
    
    enum Category: String {
        case screen
        case screen_life
        
        case yes
        case no
    }
    
    static func log(_ eventName: EventName, _ category: Category? = nil, _ itemName: String? = nil, _ value: Int64? = nil, content: String? = nil) {
        GuruAnalytics.log(event: eventName.rawValue, category: category?.rawValue, name: itemName, value: value, content: content)
    }
    
    static func logger(_ eventName: String, _ category: String?, _ itemName: String?, _ value: Int64?, content: String? = nil) {
        GuruAnalytics.log(event: eventName, category: category, name: itemName, value: value, content: content)
    }
    //    }
}

extension Logger {
    struct Ads {
        enum AdsEvent {
            case request
            case load
            case nofill
            case renderFail
            case rendered
            case impl
            case click
        }
        
        static func logEvent(_ event: AdsEvent) {
            GuruAnalytics.log(event: "ads", category: nil, name: "\(event)", value: nil)
        }
        
        static func logNativeEvent(_ event: AdsEvent) {
            GuruAnalytics.log(event: "native_ads", category: nil, name: "\(event)", value: nil)
        }
    }
}


class GuruAnalytics {
    
    static func logScreen(screenName: String) {
        log(event: "screen", category: "screen", name: screenName, value: nil)
    }
    
    //MARK: - 一、说明
    // MARK: 2. 事件参数及对应的各个平台的信息
    //https://docs.google.com/document/d/1sH7z0MxQytA45od0O70iplZjgW32nvIhniqRmzMJUWk/edit#heading=h.m9s75a11x2ci
    /**
     - event_name,      item_name,      item_category,      value
     - _eventName,      fb_content_id,  fb_content_type,    fb_level
     */
    static func log(event: String, category: String? = nil, name: String? = nil, value: Int64? = nil, content: String? = nil) {
        
        var firebaseInfo = [String: Any]()
        var facebookInfo = [String: Any]()

        defer {
            
//            #if DEBUG
                var info = firebaseInfo
                info["event_name"] = event
                cdPrint("GuruAnalytics.log.event: \(info)")
//            #endif
            
            FirebaseAnalytics.Analytics.logEvent(event, parameters: firebaseInfo)
//            AppEvents.logEvent(AppEvents.Name(rawValue: event), parameters: facebookInfo)
        }
        
        firebaseInfo[AnalyticsParameterItemName] = name

        facebookInfo["fb_content_id"] = name
        
        firebaseInfo[AnalyticsParameterContent] = content
        
        firebaseInfo[AnalyticsParameterItemCategory] = category
        facebookInfo["fb_content_type"] = category

        firebaseInfo[AnalyticsParameterValue] = value
        facebookInfo["fb_level"] = value
        
//        cdPrint(GuruAnalytics)
    }
//
    static func print<T>(file: String = #file, function: String = #function, line: Int = #line, _ message: T, color: UIColor = .white) {
//           #if DEBUG
//            swiftLog(file, function, line, message, color, false)
//           #endif
        cdPrint("file: \(file) function: \(function) message: \(message)")
       }
//
    static func log(property: String, to value: String) {
        
        #if DEBUG
            cdPrint("GuruAnalytics.log.proprty: \( [property: value])")
        #endif
        
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: property)
//        AppEvents.updateUserProperties([property: value], handler: nil)
    }
    
    static func log(userID: String?) {
        FirebaseAnalytics.Analytics.setUserID(userID)
//        AppEvents.userID = userID
        Crashlytics.sharedInstance().setUserIdentifier(userID ?? "nil")
        
        #if DEBUG
        cdPrint("GuruAnalytics.log.userID: \(userID ?? "")")
        #endif
    }
}

extension GuruAnalytics {
    enum Location: String {
        case network
    }
    
    enum Path: String {
        case facebook
    }
    /**
     NSDictionary *userInfo = @{
         NSLocalizedDescriptionKey: NSLocalizedString(@"The request failed.", nil),
         NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The response returned a 404.", nil),
         NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Does this page exist?", nil),
         ProductID: @"123456";
         UserID: @"Jane Smith"
     };

     NSError *error = [NSError domain:NSSomeErrorDomain
                               code:-1001
                               userInfo:userInfo];
     */
//    static func record(_ error: Error?, domain: String? = nil, location: Location, path: Path, maybeReason: String? = nil, userInfo: [String: Any]? = nil) {
//        record(error, domain: domain, location: "\(location)_\(path)", maybeReason: maybeReason, userInfo: userInfo)
//    }
    
//    static func record(_ error: Error?, domain: String? = nil, location: String, maybeReason: String? = nil, userInfo: [String: Any]? = nil) {
//        guard let error = error else {
//            return
//        }
//        var localizedDescription = error.localizedDescription
////        var failureReasonErrorKey: String?
//        var errorDomain: String {
//            if let domain = domain,
//                !domain.isEmpty {
//                return domain
//            } else {
//                return "com.cuddle.\(location)"
//            }
//        }
////        var errorReason = maybeReason
//        var code = 0
//        var errorUserInfo = userInfo
//
//        let reportError = NSError(domain: errorDomain, code: code, userInfo: [
//            NSLocalizedDescriptionKey: localizedDescription,
//            NSLocalizedFailureReasonErrorKey: maybeReason ?? "",
//        ])
//        Crashlytics.sharedInstance().recordError(reportError, withAdditionalUserInfo: userInfo)
//    }
    static func record(_ error: NSError, userInfo: [String: Any]?) {
        //            guard let error = error else {
        //                return
        //            }
        //            var localizedDescription = error.localizedDescription
        //    //        var failureReasonErrorKey: String?
        //            var errorDomain: String {
        //                if let domain = domain,
        //                    !domain.isEmpty {
        //                    return domain
        //                } else {
        //                    return "com.cuddle.\(location)"
        //                }
        //            }
        //    //        var errorReason = maybeReason
        //            var code = 0
        //            var errorUserInfo = userInfo
        
        //            let reportError = NSError(domain: errorDomain, code: code, userInfo: [
        //                NSLocalizedDescriptionKey: localizedDescription,
        //                NSLocalizedFailureReasonErrorKey: maybeReason ?? "",
        //            ])
        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
    }
    
//    static func record(_ code: Int, userInfo: [String: Any]?) {
//          
//           let reportError = NSError(domain: errorDomain, code: code, userInfo: [
//               NSLocalizedDescriptionKey: localizedDescription,
//               NSLocalizedFailureReasonErrorKey: maybeReason ?? "",
//           ])
//           Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
//       }
    
    
}
