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
    
    static func handle(dynamicLink url: URL, completion: @escaping (URL?) -> Void) -> Bool {
        let dynamicLinks = DynamicLinks.dynamicLinks()
        return dynamicLinks.handleUniversalLink(url) { (link, error) in
            completion(link?.url)
        }
    }
}
