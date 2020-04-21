//
//  IAP.ProductDealer.swift
//  Castbox
//
//  Created by ChenDong on 2017/12/5.
//  Copyright © 2017年 Guru. All rights reserved.
//

import Foundation
import StoreKit
//import SwiftyJSON

extension IAP {
    
    class ProductDealer: NSObject {
        let TAG = "ProductDealer"
        
        typealias OnStateType = (SKPaymentTransactionState, Error?)->Void
        fileprivate let product: IAP.Product
        fileprivate let payment: SKMutablePayment
        fileprivate var onState: OnStateType?
        private var owner: AnyObject?
        
        static func pay(_ product: IAP.Product, onState: @escaping OnStateType) {
            
            let dealer = ProductDealer(product: product)
            dealer.owner = dealer // create retain cycle
            let newOnState: OnStateType = { [weak dealer] (state, error) in
                let action = {
                    switch state {
                    case .purchased, .restored, .failed:
                        if let d = dealer {
                            SKPaymentQueue.default().remove(d)
                        }
                        dealer?.owner = nil // break retain cycle
                    default:
                        break
                    }
                    onState(state, error)
                }
                if Thread.isMainThread {
                    action()
                } else {
                    DispatchQueue.main.async {
                        action()
                    }
                }
            }
            
            dealer.onState = newOnState
        }
        
        private init(product: IAP.Product) {
            self.product = product
            self.payment = SKMutablePayment(product: product.skProduct)
            
            super.init()
            let trans = SKPaymentQueue.default().transactions
            trans.forEach { (tran) in
                if tran.payment.productIdentifier == product.skProduct.productIdentifier {
                    // https://console.firebase.google.com/u/1/project/castbox-x/crashlytics/app/ios:fm.castbox.audiobook.radio.podcast/issues/5c86156df8b88c2963ae86fd?time=last-seven-days&sessionId=300a5b00d6e24b0887c059343b38e1c3_DNE_0_v2
                    // Asynchronous.  Remove a finished (i.e. failed or completed) transaction from the queue.  Attempting to finish a purchasing transaction will throw an exception.
                    // 4.28
                    guard tran.transactionState != .purchasing else { return }
                    SKPaymentQueue.default().finishTransaction(tran) // clean previous unfinished transcations
                }
            }
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
        }
    }
}

extension IAP.ProductDealer: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        cdPrint("paymentQueue updatedTransactions: \(transactions)")
        guard let trans = transactions.first(where: { $0.payment.productIdentifier == self.payment.productIdentifier }) else {
            return
        }
        
        switch trans.transactionState {
        case .purchased, .restored, .failed:
            SKPaymentQueue.default().finishTransaction(trans)
        case .deferred, .purchasing:
            break
        default:
            break
        }
        onState?(trans.transactionState, trans.error)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    }
}
