//
//  UserProperty.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/9/19.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation

struct UserProperty {
    static func setSubscribedCount(_ ct: Int) {
        GuruAnalytics.log(property: "s_count", to: String(ct))
    }
    
    static func setPushType(_ type: String) {
        GuruAnalytics.log(property: "push_type", to: type)
    }
    
    static func setIsPro(_ isPro: Bool) {
        GuruAnalytics.log(property: "is_pro", to: "\(isPro)")
    }
    
    static func setNotificationPerm(_ status: String) {
        GuruAnalytics.log(property: "noti_perm", to: status)
    }
    
    static func setLocationPerm(_ status: String) {
        GuruAnalytics.log(property: "loc_perm", to: status)
    }
    
    static func setLockScreenOn(_ isOn: Bool) {
        GuruAnalytics.log(property: "lockscreen_on", to: "\(isOn)")
    }
    
    static func logUserID(_ uid: String) {
        GuruAnalytics.log(userID: uid)
    }
}
