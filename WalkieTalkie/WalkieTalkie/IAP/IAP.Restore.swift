//
//  IAP.Restore.swift
//  Castbox
//
//  Created by mayue_work on 2019/6/21.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import StoreKit
import RxSwift

extension IAP {
    
    struct Restore {
        
        typealias CallbackType = (Bool) -> Void
        private static var observer: RestoreObserver?
        
        static func restorePurchase(_ callback:@escaping CallbackType) {
            guard observer == nil else {
                return
            }
            let observerInstance = RestoreObserver.init()
            
            SKPaymentQueue.default().restoreCompletedTransactions()
            observerInstance.callback = callback
            IAP.Restore.observer = observerInstance
        }
        
        private class RestoreObserver: NSObject, SKPaymentTransactionObserver {
            
            var callback: CallbackType = { _ in }
            private var hasRestorablePurchases = false
            
            override init() {
                super.init()
                SKPaymentQueue.default().add(self)
            }
            
            deinit {
                SKPaymentQueue.default().remove(self)
            }
            
            // MARK: SKPaymentTransactionObserver
            
            func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
                for transaction in transactions {
                    switch transaction.transactionState {
                    case .restored:
                        queue.finishTransaction(transaction)
                        hasRestorablePurchases = true
                    default:
                        break
                    }
                }
            }
            
            func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
                if hasRestorablePurchases {
                    let _ = Request.uploadReceipt(restore: true)
                        .subscribe(onSuccess: {})
                }
                DispatchQueue.main.async {
                    self.callback(self.hasRestorablePurchases)
                    IAP.Restore.observer = nil
                }
            }
            
            func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
                DispatchQueue.main.async {
                    self.callback(false)
                    IAP.Restore.observer = nil
                }
            }
        }
    }
}
