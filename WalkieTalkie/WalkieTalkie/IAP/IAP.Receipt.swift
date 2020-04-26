//
//  IAP.Receipt.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/8/26.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation
import SwiftyStoreKit
import SwiftyUserDefaults

extension IAP {
    
    typealias RestoreCompleteType = (_ hasValidProduct: Bool)->Void
    
    private static let sharedSecret: String = "0b75276c57474ccd967e8c1d4ba45b23"
    
    static func updatePurchased(forceRefresh: Bool = false, completion: RestoreCompleteType? = nil) {
        SwiftyStoreKit.fetchReceipt(forceRefresh: forceRefresh) { (result) in
            switch result {
            case .success(let receiptData):
                IAP.validate(with: receiptData, completion: completion)
            case .error(let error):
                completion?(false)
                NSLog("Fetch Receipt Error: \(error)")
            }
        }
    }
    
    private static func validate(with receiptEncryptedData: Data, completion: RestoreCompleteType? = nil) {
        let appValidator = AppleReceiptValidator(service: .production, sharedSecret: IAP.sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appValidator) { (result) in
            switch result {
            case .success(let receipt):
                IAP.verifySubscription(in: receipt, completion: completion)
            case let .error(error):
                completion?(false)
                NSLog("Receipt validat error: \(error)")
            }
        }
    }
    
    private static func verifySubscription(in receipt: ReceiptInfo, completion: RestoreCompleteType? = nil) {
        var productIds = FireRemote.shared.value.premiumProducts
        if productIds.count < 3 {
            productIds = productIds.union(Set([IAP.productYear,
                                               IAP.productLifeTime, IAP.productMonth]))
        }
        let purchased = SwiftyStoreKit.verifySubscriptions(productIds: productIds, inReceipt: receipt)
        switch purchased {
        case let .purchased(_, items):
            Settings.shared.isProValue.value = true
            Defaults[\.purchasedItemsKey] = items.first?.productId
            completion?(true)
        default:
            Settings.shared.isProValue.value = false
            completion?(false)
        }
    }
    
    static func restorePurchased(completion: RestoreCompleteType?) {
        updatePurchased(forceRefresh: true) { (hasValidProduct) in
            let title: String = hasValidProduct ? R.string.localizable.settingsRestoreSuccessTitle() : R.string.localizable.settingsRestoreFailTitle()
            let body: String = hasValidProduct ? R.string.localizable.settingsRestoreSuccessBody() : R.string.localizable.settingsRestoreFailBody()
            let alertVC = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alertVC.addAction(.init(title: R.string.localizable.alertOk(), style: .default, handler: nil))
            if let vc = UIApplication.shared.keyWindow?.topViewController() {
                vc.present(alertVC, animated: true, completion: nil)
            }
            completion?(hasValidProduct)
        }
    }
    
    static func verifyLocalReceipts() {
        if let _ = SwiftyStoreKit.localReceiptData {
            updatePurchased()
        } else {
            Settings.shared.isProValue.value = false
        }
    }
}
