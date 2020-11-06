//
//  Logger.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import FirebaseCrashlytics
//import Crashlytics
import StoreKit

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
    
    static func logger(_ eventName: String, _ category: String?, _ itemName: String? = nil, _ value: Int64? = nil, content: String? = nil) {
        GuruAnalytics.log(event: eventName, category: category, name: itemName, value: value, content: content)
    }
    //    }
}

extension Logger {
    struct Ads {
        enum AdsEvent: String {
            case ads_load
            case ads_loaded
            case ads_failed
            case ads_imp
            case ads_clk
            case ads_close
            
            case rads_load
            case rads_loaded
            case rads_failed
            case rads_imp
            case rads_clk
            case rads_close
        }
        
        static func logEvent(_ event: AdsEvent, _ itemName: Logger.Screen.Node.Start? = nil, value: Int64? = nil) {
            GuruAnalytics.log(event: event.rawValue, category: nil, name: itemName?.rawValue, value: value)
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
    static func log(event: String, category: String? = nil, name: String? = nil, value: Int64? = nil, content: String? = nil,
                    iap_ab_group: String? = nil) {
        
        var firebaseInfo = [String: Any]()
//        var facebookInfo = [String: Any]()

        defer {
            
            var info = firebaseInfo
            info["event_name"] = event
            #if DEBUG
                cdPrint("GuruAnalytics.log.event: \(info)")
            #else
            FirebaseAnalytics.Analytics.logEvent(event, parameters: firebaseInfo)
            #endif
        }
        
        firebaseInfo[AnalyticsParameterItemName] = name

//        facebookInfo["fb_content_id"] = name
        
        firebaseInfo[AnalyticsParameterContent] = content
        
        firebaseInfo[AnalyticsParameterItemCategory] = category
//        facebookInfo["fb_content_type"] = category

        firebaseInfo[AnalyticsParameterValue] = value
//        facebookInfo["fb_level"] = value
        firebaseInfo["iap_ab_group"] = iap_ab_group
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
//        Crashlytics.sharedInstance().setUserIdentifier(userID ?? "nil")
        Crashlytics.crashlytics().setUserID(userID ?? "nil")
        
        #if DEBUG
        cdPrint("GuruAnalytics.log.userID: \(userID ?? "")")
        #endif
    }
    
    static func setUserProperty(_ value: String?, forName name: String) {
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: name)
        
        #if DEBUG
        cdPrint("GuruAnalytics.log.setUserProperty name: \(name) value: \(value ?? "")")
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
        Crashlytics.crashlytics().record(error: error)
//        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
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

extension Logger {
    struct IAP {
        
        /// 会员落地页展现来源
        enum ActionSource: String {
            
//            case store
//            case setting_pro
//            case lockscreen
//            case noads
//            // 通用URI跳转，包含Push和内部广告
//            case uri
//            // 通过URI直接购买
//            case uri_buy
//            // 播放页移除广告
//            case remove_ads
//            // Remote Config配置的自动弹出逻辑
//            case auto
            // api控制的首次弹出
            case first_open
            case setting
            case secret_channel_create
            case mute
            case iap_tip
        }
        
        static func logImp(_ source: ActionSource) {
            GuruAnalytics.log(event: "iap_imp", category: "\(source)", name: nil, value: nil)
            if source == .first_open {
                Logger.FirstOpen.logImp()
            }
        }
        
        static func logClose(_ source: ActionSource) {
            GuruAnalytics.log(event: "iap_close", category: "\(source)", name: nil, value: nil)
            if source == .first_open {
                Logger.FirstOpen.logClose()
            }
        }
        
        static func logPurchase(productId: String, source: ActionSource) {
            GuruAnalytics.log(event: "iap_clk", category: source.rawValue, name: productId, value: nil)
            if source == .first_open {
                Logger.FirstOpen.logClick(productId: productId)
            }
        }
        
        static func logPurchaseResult(product: SKProduct, source: ActionSource, isSuccess: Bool) {
            GuruAnalytics.log(event: "iap_ret", category: source.rawValue, name: product.productIdentifier, value: isSuccess ? 1 : 0)
            if source == .first_open {
                Logger.FirstOpen.logPurchaseResult(productId: product.productIdentifier, isSuccess: isSuccess)
            }
        }
        
        static func logPurchaseFailByIdentifier(identifier: String, source: ActionSource) {
            GuruAnalytics.log(event: "iap_ret", category: source.rawValue, name: identifier, value: 0)
            if source == .first_open {
                Logger.FirstOpen.logPurchaseResult(productId: identifier, isSuccess: false)
            }

        }
    }
    
}

extension Logger {
    struct FirstOpen {
        static func logImp() {
            GuruAnalytics.log(event: "first_open_iap_imp", category: nil, name: nil, value: nil)
        }
        
        static func logClose() {
            GuruAnalytics.log(event: "first_open_iap_close", category: nil, name: nil, value: nil)
        }
        
        static func logClick(productId: String) {
            GuruAnalytics.log(event: "first_open_iap_clk", category: productId, name: nil, value: nil)
        }
        
        static func logPurchaseResult(productId: String, isSuccess: Bool) {
            GuruAnalytics.log(event: "first_open_iap_ret", category: productId, name: nil, value: isSuccess ? 1 : 0)
            if isSuccess {
                GuruAnalytics.log(event: "first_open_iap_ret_true", category: productId, name: nil, value: nil)
            } else {
                GuruAnalytics.log(event: "first_open_iap_ret_false", category: productId, name: nil, value: nil)
            }
        }
    }
}

extension Logger {
    struct Report {
        static func logImp(itemIndex: Int, channelName: String?) {
            GuruAnalytics.log(event: "report_room", category: "item_\(itemIndex)", name: channelName, value: nil)
        }
    }
}
