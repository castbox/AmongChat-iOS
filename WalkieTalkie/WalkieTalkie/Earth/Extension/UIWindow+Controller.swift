//
//  UIWindow+Controller.swift
//  HUFUWallet
//
//  Created by Wilson on 2018/5/31.
//  Copyright © 2018 Hufu inc. All rights reserved.
//

import UIKit

extension UIWindow {
    func topRootController() -> UIViewController? {
        var topController: UIViewController? = rootViewController
        //  Getting top root ViewController
        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
        }
        //  Returning top root ViewController
        return topController
    }
    
    func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? rootViewController
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return topViewController(top)
            } else if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        
        return base
    }
}
