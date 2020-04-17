//
//  NavigationViewController.swift
//  xWallet_ios
//
//  Created by Wilson on 2019/1/20.
//  Copyright © 2019 Anmobi inc. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.delegate = self
        self.interactivePopGestureRecognizer?.delegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if topViewController != nil {
            return (topViewController?.preferredStatusBarStyle)!
        }
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        if topViewController != nil {
            return topViewController?.prefersStatusBarHidden ?? false
        }
        return false
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if topViewController != nil {
            return (topViewController?.preferredStatusBarUpdateAnimation)!
        }
        return .fade
    }
    
    // MARK: - Rotate
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if topViewController != nil {
            return (topViewController?.preferredInterfaceOrientationForPresentation)!
        }
        return .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if topViewController != nil {
            return (topViewController?.supportedInterfaceOrientations)!
        }
        return .allButUpsideDown
    }
    
    override var shouldAutorotate: Bool {
        if topViewController != nil {
            return topViewController?.shouldAutorotate ?? false
        }
        return topViewController?.shouldAutorotate ?? false
    }
}

extension NavigationViewController: UINavigationControllerDelegate {
    
}

extension NavigationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == interactivePopGestureRecognizer {
            if viewControllers.count < 2 || visibleViewController == viewControllers[0] {
                return false
            } else {
                guard let topController = topViewController as? GestureBackable  else {
                    return true
                }
                return topController.isEnableScreenEdgeGesture
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if interactivePopGestureRecognizer == gestureRecognizer {
            if otherGestureRecognizer.view is UIScrollView {
                let scrollView = otherGestureRecognizer.view as? UIScrollView
                if (scrollView?.contentSize.width ?? 0.0) > view.bounds.width && scrollView?.contentOffset.x == 0 {
                    return true
                }
            }
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if interactivePopGestureRecognizer == gestureRecognizer {
            return true
        }
        return false
    }
 
}
