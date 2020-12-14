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
//        return ["wt.i.sub.vip.p1y", //29.99
//                "wt.i.sub.vip.p1y1", //19.99
//            ][Settings.shared.userInAGroup.int]
        return "wtas.i.sub.vip.p1y"
    }
    static let productMonth: String = "wtas.i.sub.vip.p1m"
    static let productLifeTime: String = "wtas.i.iap.vip"
    static let productWeek: String = "wtas.i.sub.vip.p1w"
    static var isWeekProductInReview: Bool {
        return false
    }
    
    static func prefetchProducts() {
        var productIds: Set<String> {
            return Set([productWeek, productMonth, productYear, productLifeTime])
        }
        
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

extension IAP {
    
    struct ProductInfo {
        let identifier: String
        //        let period: String
        @available(*, deprecated, message:"")
        var isPopular: Bool = false
        @available(*, deprecated, message:"")
        let actionDesc: String?
        let termsDesc: String?
        let product: IAP.Product
    }
    
    static var productInfoMap: Observable<[String: ProductInfo]> {
        return IAP.productsValue
            .observeOn(Scheduler.backgroundScheduler)
            .map { (productMap) -> [String: ProductInfo] in
                var newMap = [String: ProductInfo]()
                productMap.forEach({ (key, value) in
                    let price = value.skProduct.localizedPrice
                    var actionDesc: String
                    var termsDesc: String
                    switch value.info.category {
                    case let .sub(free: free, renewal: _):
                        if free != nil {
                            actionDesc = R.string.localizable.premiumFreeTrial()
                            termsDesc = R.string.localizable.premiumSubscriptionDetailFree(value.skProduct.localizedTitle, price)
                        } else {
                            actionDesc = R.string.localizable.premiumFreeTrial()
                            termsDesc = R.string.localizable.premiumSubscriptionDetailNormal(value.skProduct.localizedTitle, price)
                        }
                    case .lifetime:
                        actionDesc = R.string.localizable.premiumLifetime()
                        termsDesc = R.string.localizable.premiumSubscriptionDetailLifetime()
                    }
                    let info = ProductInfo(identifier: value.skProduct.productIdentifier, actionDesc: actionDesc, termsDesc: termsDesc, product: value)
                    newMap[key] = info
                })
                return newMap
        }
        .observeOn(MainScheduler.instance)
        .timeout(RxTimeInterval.seconds(10), scheduler: MainScheduler.instance)
    }

}

extension IAP.ProductInfo {
    
    struct PriceInfo {
        let freePeriod: String
        let price: String
        let renewalPeriod: String
        let adj_renewalPeriod: String
    }
    
    var priceInfo: PriceInfo {
        switch product.info.category {
        case .sub(free: let period, renewal: let renewal):
            let renewDuration: String = renewal.asPerDuration()
            return PriceInfo(freePeriod: period?.asDuration() ?? "", price: product.skProduct.localizedPrice,
                             renewalPeriod: renewDuration, adj_renewalPeriod: renewal.unit.adjString)
            
        case .lifetime:
            return PriceInfo(freePeriod: "", price: product.skProduct.localizedPrice,
                             renewalPeriod: R.string.localizable.premiumLifetime(), adj_renewalPeriod: R.string.localizable.premiumLifetime())
        }
        
    }
}

