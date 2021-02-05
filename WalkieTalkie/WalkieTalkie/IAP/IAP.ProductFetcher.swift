//
//  IAP.ProductFetcher.swift
//  Castbox
//
//  Created by ChenDong on 2017/12/4.
//  Copyright © 2017年 Guru. All rights reserved.
//

import Foundation
import StoreKit

extension IAP {
    
    class Product {
        
        let skProduct: SKProduct
        let info: Info
        
        init?(_ skProduct: SKProduct) {
            guard let info = IAP.Product.parse(skProduct) else {
                assert(false, "not support this kind of product")
                return nil
            }
            self.skProduct = skProduct
            self.info = info
        }
    }
    
    class ProductFetcher: NSObject {
        
        typealias CompletionType = (Error?, [String: Product])->Void
        
        fileprivate(set) var pids: Set<String> = []
        fileprivate(set) var request: SKProductsRequest?
        fileprivate(set) var completion: CompletionType?
        fileprivate var owner: AnyObject?
        
        static func fetchProducts(of pids: Set<String>, completion: @escaping CompletionType) {
            let fetcher = ProductFetcher()
            fetcher.owner = fetcher
            
            fetcher.fetchProducts(of: pids) { [weak fetcher] (error, products) in
                fetcher?.owner = nil // break retain cycle
                completion(error, products)
            }
        }
        
        private override init() {
            super.init()
        }
        
        fileprivate func fetchProducts(of pids: Set<String>, completion: @escaping CompletionType) {
            guard pids.count > 0 else {
                completion(nil, [:])
                return
            }
            
            self.pids = pids
            self.completion = completion
            self.request?.delegate = nil

            self.request = SKProductsRequest(productIdentifiers: pids)
            self.request?.delegate = self
            self.request?.start()
        }
    }
}

extension IAP.ProductFetcher: SKProductsRequestDelegate {
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard self.request === request else { return }
        self.completion?(error, [:])
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard self.request === request else { return }
        
        var products: [String: IAP.Product] = [:]
        response.products.forEach { (p) in
             _ = IAP.Product(p).flatMap({ products[$0.skProduct.productIdentifier] = $0 })
        }
        self.completion?(nil, products)
    }
}

extension SKProduct {
    
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price) ?? "Unknown"
    }
}


extension IAP.Product {
    
    enum Content {
        case premium
        case consumable
    }
    
    enum Category {
        case sub(free: Period?, renewal: Period) // 比如，免费 7天，$xxx/2月
        case lifetime
        case oneTime
    }

    class Period {
        
        enum Unit: String {
            case day = "d"
            case week = "w"
            case month = "m"
            case year = "y"
            case life = "l"
            
            var localizedString: String {
                switch self {
                case .day:
                    return NSLocalizedString("day", comment: "day")
                case .week:
                    return NSLocalizedString("week", comment: "week")
                case .month:
                    return NSLocalizedString("month", comment: "month")
                case .year:
                    return NSLocalizedString("year", comment: "year")
                case .life:
                    return NSLocalizedString("lifeTime", comment: "lifeTime")
                }
            }
            
            var pluralLocalizedString: String {
                switch self {
                case .day:
                    return NSLocalizedString("days", comment: "days")
                case .week:
                    return NSLocalizedString("weeks", comment: "weeks")
                case .month:
                    return NSLocalizedString("months", comment: "months")
                case .year:
                    return NSLocalizedString("years", comment: "years")
                case .life:
                    return NSLocalizedString("lifeTime", comment: "lifeTime")
                }
            }
            
            var adjString: String {
                switch self {
                case .day:
                    return NSLocalizedString("daily", comment: "daily")
                case .week:
                    return NSLocalizedString("weekly", comment: "weekly")
                case .month:
                    return NSLocalizedString("monthly", comment: "monthly")
                case .year:
                    return NSLocalizedString("yearly", comment: "yearly")
                case .life:
                    return NSLocalizedString("lifeTime", comment: "lifeTime")
                }
            }
        }
        
        let num: Int
        let unit: Unit
        
        init(_ num: Int, _ unit: Unit) {
            self.num = num
            self.unit = unit
        }
        
        func asDuration()->String {
            var st = ""
            st += String(num)
            st += " "
            let perDuration = num > 1 ? unit.pluralLocalizedString : unit.localizedString
            st += perDuration.firstCharacterUpperCase() ?? perDuration
//            st += num > 1 ? unit.pluralLocalizedString : unit.localizedString
            return st
        }
        
        func asPerDuration()->String {
            var st = ""
            st += num > 1 ? "\(num) " : ""
            st += num > 1 ? unit.pluralLocalizedString : unit.localizedString
            return st
        }
    }
    
    struct Info {
        let content: Content
        let category: Category
    }
        
    static func parse(_ product: SKProduct) -> Info? {
        if #available(iOS 11.2, *) {
            if let skPeriod = product.subscriptionPeriod,
                let subPeriod = parsePeriod(skPeriod, periodType: .subscription) {
                var freeTrialPeriod: Period? = nil
                if let dis = product.introductoryPrice,
                    dis.paymentMode == .freeTrial,
                    let period = parsePeriod(dis.subscriptionPeriod, periodType: .introductory, numberOfPeriods: dis.numberOfPeriods) {
                    freeTrialPeriod = period
                }
                return Info(content: .premium, category: .sub(free: freeTrialPeriod, renewal: subPeriod))
            }
        }
        
        var category: Category? = nil
        var content: Content = .premium
        
        switch product.productIdentifier {
        case let str where str.starts(with: IAP.productWeek):
             category = .sub(free: nil, renewal: Period(1, .week))
        case let str where str.starts(with: IAP.productMonth):
            category = .sub(free: nil, renewal: Period(1, .month))
        case let str where str.starts(with: IAP.productYear):
            category = .sub(free: nil, renewal: Period(1, .year))
        case let str where str.starts(with: IAP.productLifeTime):
            category = .sub(free: nil, renewal: Period(Int.max, .year))
        case let str where str.starts(with: IAP.productPetPrefix):
            category = .oneTime
            content = .consumable
        default:
            ()
        }
        if let cat = category {
            return Info(content: content, category: cat)
        }
        return nil
    }
    
    enum PeriodType {
        case introductory
        case subscription
    }
    
    @available(iOS 11.2, *)
    static func parsePeriod(_ p: SKProductSubscriptionPeriod, periodType: PeriodType, numberOfPeriods: Int = 1)-> Period? {
        var unit: Period.Unit
        switch p.unit {
        case .day:
            unit = .day
        case .week:
            unit = .week
        case .month:
            unit = .month
        case .year:
            unit = .year
        @unknown default:
            return nil
        }
        
        // 修复SKProduct把一周的订阅展现为7天， 把7天的试用展现为一周
        let amount = p.numberOfUnits * numberOfPeriods
        switch (amount, unit, periodType) {
        case (7, .day, .subscription):
            return Period(1, .week)
        case (1, .week, .introductory):
            return Period(7, .day)
        default:
            return Period(amount, unit)
        }
    }
}
