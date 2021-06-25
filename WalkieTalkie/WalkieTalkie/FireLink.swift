//
//  FireLink.swift
//  CastboxFirebase
//
//  Created by ChenDong on 2018/4/26.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation
import FirebaseDynamicLinks

class FireLink {
    
    static func handle(dynamicLink url: URL, completion: @escaping (URL?, Error?) -> Void) -> Bool {
        let dynamicLinks = DynamicLinks.dynamicLinks()
        ////解析第三方分享回流: com.talkie.walkie.chat.among://google/link/?match_type=default&request_ip_version=IP%5FV4&utm_source=snapchat&utm_campaign=snapchat%5Fshare&utm_medium=i%5Fshare&deep_link_id=https%3A%2F%2Famong%2Echat%2Fuid%2F110007&match_message=One%20pre%2Dinstall%20link%20matched%20for%20this%20device%2E
        if dynamicLinks.shouldHandleDynamicLink(fromCustomSchemeURL: url),
           let link = dynamicLinks.dynamicLink(fromCustomSchemeURL: url),
           let linkUrl = link.url {
            completion(linkUrl, nil)
            return true
        }
        return dynamicLinks.handleUniversalLink(url) { (link, error) in
            completion(link?.url, error)
        }
    }
}
