//
//  Modal.Container.swift
//  Cuddle
//
//  Created by Marry on 2019/7/11.
//  Copyright © 2019 Guru. All rights reserved.
//

import UIKit

extension Modal {
    
    class ContainerDismiss: NSObject, UIViewControllerAnimatedTransitioning {
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return AnimationDuration.normal.rawValue
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            
            let fromView: UIView
            if let view = transitionContext.view(forKey: .from) {
                fromView = view
            } else if let view = transitionContext.viewController(forKey: .from)?.view {
                fromView = view
            } else {
                return
            }
            
            let cover = transitionContext.containerView.subviews.filter({ $0.isKind(of: Modal.Cover.self) }).first
            
            UIView.animate(withDuration: AnimationDuration.normal.rawValue, animations: {
                cover?.alpha = 0.0
                fromView.frame = CGRect(x: 0.0,
                                        y: UIScreen.main.bounds.height,
                                        width: UIScreen.main.bounds.width,
                                        height: UIScreen.main.bounds.height)
            }) { (done) in
                if done {
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    fromView.removeFromSuperview()
                    cover?.removeFromSuperview()
                }
            }
        }
    }
    
    class ContainerPresent: NSObject, UIViewControllerAnimatedTransitioning {
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return AnimationDuration.normal.rawValue
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            
            let toController = transitionContext.viewController(forKey: .to)
            
            let toView: UIView
            if let view = transitionContext.view(forKey: .to) {
                toView = view
            } else if let view = toController?.view {
                toView = view
            } else {
                return
            }
            
            let cover = Modal.Cover(frame: UIScreen.main.bounds)
            cover.onTapped = {
                guard let controller = toController else { return }
                controller.dismiss(animated: true, completion: nil)
            }
            
            var alpha: CGFloat = 1.0
            var isClear: Bool = false
            var height: CGFloat = 0
            if let vc = toController, let modal = vc.modal() {
                // 添加圆角
                if modal.containerCornerRadius() != 0 {
//                    addCorner(to: toView)
                    toView.addCorner(with: modal.containerCornerRadius())
                }
                // 设置高度
                height = modal.height()
                if modal.style() == .customHeight {
                    height = UIScreen.main.bounds.height - height
                }
                // 设置alpha
                isClear = modal.coverAlpha() == 0
                if isClear {
                    cover.alpha = 1.0
                    cover.backgroundColor = .clear
                } else {
                    cover.alpha = 0.0
                    alpha = modal.coverAlpha()
                }
            }
            
            transitionContext.containerView.addSubview(cover)
            transitionContext.containerView.addSubview(toView)
            toView.frame = CGRect(x: 0.0,
                                  y: UIScreen.main.bounds.height,
                                  width: UIScreen.main.bounds.width,
                                  height: UIScreen.main.bounds.height)
            
            UIView.animate(withDuration: AnimationDuration.normal.rawValue, animations: {
                toView.frame = CGRect(x: 0.0,
                                      y: height,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.height)
                if !isClear {
                    cover.alpha = alpha
                }
            }) { (done) in
                if done {
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            }
        }
    }
}

extension UIView {
    func addCorner(with radius: CGFloat, corners: UIRectCorner = [UIRectCorner.topLeft, UIRectCorner.topRight]) {
        
        let bounds = CGRect(x: 0.0, y: 0.0, width: self.bounds.width, height: self.bounds.height)
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
}
