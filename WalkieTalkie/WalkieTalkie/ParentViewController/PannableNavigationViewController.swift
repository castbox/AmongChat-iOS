//
//  PannableNavigationController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 12/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import HWPanModal

class PannableNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme(.backgroundBlack)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        self.panModalSetNeedsLayoutUpdate()
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        let vc = super.popViewController(animated: animated)
        self.panModalSetNeedsLayoutUpdate()
        return vc
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let vcs = super.popToRootViewController(animated: animated)
        self.panModalSetNeedsLayoutUpdate()
        return vcs
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let vcs = super.popToViewController(viewController, animated: animated)
        self.panModalSetNeedsLayoutUpdate()
        return vcs
    }
    
    override func panScrollable() -> UIScrollView? {
        
        if let vc = topViewController, vc.conforms(to: HWPanModalPresentable.self) {
            return (vc as HWPanModalPresentable).panScrollable()
        }
        return nil
    }
    
    override func topOffset() -> CGFloat {
        return 0
    }
    
    override func transitionDuration() -> TimeInterval {
        return 0.25
    }
        
    override func shouldRoundTopCorners() -> Bool {
        return false
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
    override func allowScreenEdgeInteractive() -> Bool {
        return false
    }
    
}
