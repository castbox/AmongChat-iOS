//
//  IAP.ConsumableProduct.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/2/3.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import StoreKit
import RxSwift
import RxCocoa

extension IAP {
    
    private(set) static var consumableProducts = [String : IAP.Product]()
    
    static let productPetPrefix: String = "wtas.i.iap.pet"
    
    static func fetchConsumableProducts(_ ids: [String]) -> Single<[String : IAP.Product]> {
        
        let cachedIds = Set(consumableProducts.values.map({ $0.skProduct.productIdentifier }))
        
        if cachedIds.contains(ids) {
            return Single.just(consumableProducts)
        }
        
        let productIds = Set(ids)
        return Single.create { (subscriber) -> Disposable in
            
            IAP.ProductFetcher.fetchProducts(of: productIds) { (error, productMap) in
                
                guard error == nil else {
                    subscriber(.error(error!))
                    return
                }
                
                if productMap.count == productIds.count {
                    
                    consumableProducts.merge(productMap, uniquingKeysWith: { $1 })
                    subscriber(.success(productMap))
                } else {
                    subscriber(.error(NSError(domain: "IAP.ConsumableProducts", code: 400, userInfo: nil)))
                }
            }
            
            return Disposables.create()
        }
        
    }
}
