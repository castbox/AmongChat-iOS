//
//  UIView.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/11/20.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import UIKit

extension UIView {
    
    func addSubviews(views: UIView...) {
        views.forEach { (subview) in
            addSubview(subview)
        }
    }
    
    
    /// Method for searchBar subview search
    var recursiveSubviews: [UIView] {
        return self.subviews + self.subviews.flatMap { $0.recursiveSubviews }
    }

    func subviews<T: UIView>(ofType: T.Type) -> [T] {
        return self.recursiveSubviews.compactMap { $0 as? T }
    }
    
    class func springAnimate(_ animation: @escaping () -> Void, completion: ((Bool)->Void)? = nil) {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 10.0, initialSpringVelocity: 10.0, options: .curveEaseInOut, animations: animation, completion: completion)
    }
    
    static func propertyAnimation(duration: TimeInterval = AnimationDuration.normal.rawValue,
                              delay: TimeInterval = 0,
                              dampingRatio: CGFloat = 0.8,
                              animation: @escaping () -> Void,
                              completion: ((Bool) -> Void)? = nil) {
        let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: dampingRatio, animations: {
            animation()
        })
        transitionAnimator.addCompletion { _ in
            completion?(true)
        }
        transitionAnimator.startAnimation()
    }
}

