//
//  IAP.SubscriptionProduct.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/9/5.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import RxSwift
import SwiftyStoreKit

extension IAP {
    static let productsValue = ReplaySubject<[String: IAP.Product]>.create(bufferSize: 1)
    
    static var productYear: String {
        return ["wt.i.sub.vip.p1y", //29.99
                "wt.i.sub.vip.p1y1", //19.99
            ][Settings.shared.userInAGroup.int]
    }
    static let productMonth: String = "wt.i.sub.vip.p1m"
    static let productLifeTime: String = "wt.i.iap.vip"
    
    static func prefetchProducts() {
        let productIds = Set([productYear, productMonth, productLifeTime])
        
        IAP.ProductFetcher.fetchProducts(of: productIds) { (error, productMap) in
            guard error == nil else {
                NSLog("[prefetchProducts] Fetch Product Error:\(error!)")
                return
            }
            if productMap.count == productIds.count {
                IAP.productsValue.onNext(productMap)
                NSLog("[prefetchProducts] Fetch Products Success")
            } else {
                NSLog("[prefetchProducts] Missing Products")
            }
        }
    }
}
