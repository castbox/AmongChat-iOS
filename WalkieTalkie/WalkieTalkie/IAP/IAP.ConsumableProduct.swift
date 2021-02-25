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
    
    private static let consumableProductsRelay = BehaviorRelay<[String : IAP.Product]>(value: [:])
    
    static var consumableProducts: [String : IAP.Product] {
        return consumableProductsRelay.value
    }
    
    static var consumableProductsObservable: Observable<[String : IAP.Product]> {
        return consumableProductsRelay.asObservable()
    }
    
    static let productPetPrefix: String = "wtas.iac.iap.pet"
    
    static func refreshConsumableProducts(_ ids: [String]) {
        
        let cachedIds = Set(consumableProducts.values.map({ $0.skProduct.productIdentifier }))
        
        if cachedIds.contains(ids) {
            return
        }
        
        let productIds = Set(ids)
        
        IAP.ProductFetcher.fetchProducts(of: productIds) { (error, productMap) in
            
            guard error == nil else {
                return
            }
            
            if productMap.count > 0 {
                var cachedMap = consumableProductsRelay.value
                cachedMap.merge(productMap, uniquingKeysWith: { $1 })
                consumableProductsRelay.accept(cachedMap)
            }
        }
    }
}
