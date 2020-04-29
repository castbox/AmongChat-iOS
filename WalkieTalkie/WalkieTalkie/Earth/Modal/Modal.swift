//
//  Modal.swift
//  Castbox
//
//  Created by lazy on 2018/12/21.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit

protocol Modalable {
    func style() -> Modal.Style
    func height() -> CGFloat
    func modalPresentationStyle() -> UIModalPresentationStyle
    func cornerRadius() -> CGFloat
    func coverAlpha() -> CGFloat
    func canAutoDismiss() -> Bool
}

extension Modalable {
    func cornerRadius() -> CGFloat {
        return 15
    }
    func coverAlpha() -> CGFloat {
        return 0.6
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}

struct Modal {
    enum Style {
        case topOffset
        case customHeight
    }
}

extension UIViewController {
    func modal() -> Modalable? {
        var modal: Modalable?
        if let navigationController = self as? UINavigationController,
            let root = navigationController.children.first as? Modalable {
            modal = root
        } else if let viewController = self as? Modalable {
            modal = viewController
        } else {
            modal = nil
        }
        return modal
    }
}

extension Modalable where Self: UIViewController {
    private var coverViewTag: Int {
        return 10034
    }
    
    func showModal(in container: UIViewController?) {
        guard let container = container else {
            return
        }
        let isNotAdded = container.children.filter { $0 is Self }.isEmpty
        guard isNotAdded else {
            return
        }
        let height = Frame.Screen.height - self.height()
        view.frame = CGRect(x: 0, y: Frame.Screen.height, width: Frame.Screen.width, height: Frame.Screen.height)
        //add cover
        let cover = Modal.Cover(frame: UIScreen.main.bounds)
        cover.tag = coverViewTag

        let dismissBlock: (UIView) -> Void = { cover in
            let transitionAnimator = UIViewPropertyAnimator(duration: AnimationDuration.normalSlow.rawValue, dampingRatio: 1, animations: { [weak self] in
                self?.view.frame = CGRect(x: 0.0,
                                          y: Frame.Screen.height,
                                          width: UIScreen.main.bounds.width,
                                          height: UIScreen.main.bounds.height)
                cover.alpha = 0
            })
            transitionAnimator.addCompletion { [weak self] _ in
                self?.willMove(toParent: nil)
                self?.view.removeFromSuperview()
                self?.removeFromParent()
                cover.removeFromSuperview()
            }
            transitionAnimator.startAnimation()
        }
        
        cover.onTapped = { [weak self] in
            guard let `self` = self,
                self.canAutoDismiss() else {
                    return
            }
            dismissBlock(cover)
        }
        
        cover.alpha = 0
        container.view.addSubview(cover)
        self.willMove(toParent: container)
        container.addChild(self)
        container.view.addSubview(view)
        if cornerRadius() > 0 {
            view.addCorner(with: cornerRadius())
        }
        
        let coverAlpha = self.coverAlpha()
        let transitionAnimator = UIViewPropertyAnimator(duration: AnimationDuration.normalSlow.rawValue, dampingRatio: 1, animations: {
            self.view.frame = CGRect(x: 0.0,
                                     y: height,
                                     width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
            cover.alpha = coverAlpha > 0 ? coverAlpha : 0.1
        })
        transitionAnimator.startAnimation()
    }
    
    func hideModal(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let parent = self.parent,
            let cover = parent.view.viewWithTag(coverViewTag) as? Modal.Cover else {
            return
        }
        //hide
        cover.onClickVew()
        completion?()
    }
}
