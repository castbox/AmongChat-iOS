//
//  UIViewControllerStoryProductExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import StoreKit

extension UIViewController {
    
    func showStoreProduct(with appId: Double) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        let parameters = [SKStoreProductParameterITunesItemIdentifier :
                                NSNumber(value: appId)]
        storeViewController.loadProduct(withParameters: parameters,
                    completionBlock: { result, error in
            if !result {
                
            }
        })
        present(storeViewController,
                        animated: true, completion: nil)
    }
}

extension UIViewController: SKStoreProductViewControllerDelegate {
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
