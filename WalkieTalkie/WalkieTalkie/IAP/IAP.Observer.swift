//
//  IAP.Observer.swift
//  Castbox
//
//  Created by ChenDong on 2018/9/11.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation
import StoreKit
import RxSwift

extension IAP {
    /* 模拟从 App Store IAP Promotion 点击的效果
     itms-services://?action=purchaseIntent&bundleId=fm.castbox.audiobook.radio.podcast&productIdentifier=castbox.premium
     
     itms-services://?action=purchaseIntent&bundleId=fm.castbox.audiobook.radio.podcast&productIdentifier=cb.i.sub.ch.1086477.p1m
     */
    /// 为了监听从 Apple Store IAP Promotion 过来的购买请求而设立的单例。
    class Observer: NSObject, SKPaymentTransactionObserver {
        static let shared = Observer()
        
        override init() {
            super.init()
            SKPaymentQueue.default().add(self)
        }
        
        func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            
        }
        
        func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
            guard let info = IAP.Product.parse(product) else { return false }
            switch info.content {
            case .premium, .consumable:
                /// not supported
                ()
//                let vc = PremiumController()
//                vc.source = .store
//                vc.byPresenting = true
//                TabController.shared.present(vc, animated: true, completion: nil)
            }
            return false
        }
    }
}
