//
//  ApiManager.ErrorHandle.swift
//  Moya-Cuddle
//
//  Created by Wilson-Yuan on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import UIKit

protocol HttpRequestHandle {
    static func handle(httpResponse response: Json?, error: ResponseError?)
}

extension APIService {
    
    class ErrorHandle: NSObject, HttpRequestHandle {
        private static let `default` = ErrorHandle()
        private var alertController: UIAlertController?
        private var appDelegate: AppDelegate {
            return UIApplication.shared.delegate as! AppDelegate
        }
        
        static func handle(httpResponse response: Json?, error: ResponseError?) {
            ErrorHandle.default.handle(response, error: error)
        }
    }
}

private extension APIService.ErrorHandle {
    
    func handle(_ response: Json?, error: ResponseError?) {
        //        guard let error = error else {
        //            return syncCommonData(response)
        //        }
        //        handle(errorCode: error.code, message: error.message)
    }
    
    func handle(errorCode code: ResponseError.Code, message: String? = nil) {
        //        switch code {
        //        case .forceUpgrade:
        //            showForceUpgradeAlert(withMessage: message)
        //        default:
        //            cdPrint("code: \(code)")
        //        }
    }
    
    func showForceUpgradeAlert(withMessage message: String?) {
        guard self.alertController == nil else {
            return
        }
        
        let title: String = NSLocalizedString("Upgrade app", comment: "Upgrade app")
        var message = message
        if message == nil {
            message = NSLocalizedString("Your app version was deprecated. You must upgrade your app.", comment: "Your app version was deprecated. You must upgrade your app.")
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let upgradeAction = UIAlertAction(title: title, style: .default, handler: {[weak self] (_ action: UIAlertAction) -> Void in
            self?.alertController = nil
//            guard let appstoreUrl = URL(string: WalletConfig.appStoreUrl) else { return }
//            if #available(iOS 10.0, *) {
//                UIApplication.shared.open(appstoreUrl, options: [:], completionHandler: nil)
//            } else {
//                // Fallback on earlier versions
//                UIApplication.shared.openURL(appstoreUrl)
//            }
        })
        
        alertController.addAction(upgradeAction)
        self.alertController = alertController
        
        appDelegate.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}

