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
    func containerCornerRadius() -> CGFloat
    func coverAlpha() -> CGFloat
    func canAutoDismiss() -> Bool
}

extension Modalable {
    func containerCornerRadius() -> CGFloat {
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
        case alpha
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
        let style = self.style()
        var initY: CGFloat {
            if style == .alpha {
                return 0
            } else {
                return Frame.Screen.height
            }
        }
        view.frame = CGRect(x: 0, y: initY, width: Frame.Screen.width, height: Frame.Screen.height)
        view.alpha = (style != .alpha).int.cgFloat
        //add cover
        let cover = Modal.Cover(frame: UIScreen.main.bounds)
        cover.tag = coverViewTag

        let dismissBlock: (UIView) -> Void = { [weak self] coverView in
            guard let `self` = self else { return }
            let transitionAnimator = UIViewPropertyAnimator(duration: AnimationDuration.normalSlow.rawValue, dampingRatio: 1, animations: { [weak self] in
                if style != .alpha {
                    self?.view.frame = CGRect(x: 0.0,
                                              y: Frame.Screen.height,
                                              width: UIScreen.main.bounds.width,
                                              height: UIScreen.main.bounds.height)
                } else {
                    self?.view.alpha = 0
                }
                coverView.alpha = 0
            })
            transitionAnimator.addCompletion { [weak self] _ in
                self?.willMove(toParent: nil)
                self?.view.removeFromSuperview()
                self?.removeFromParent()
                coverView.removeFromSuperview()
            }
            transitionAnimator.startAnimation()
        }
        
        cover.onTapped = { [weak self, weak cover] in
            guard let `self` = self,
                self.canAutoDismiss(),
                let cover = cover else {
                    return
            }
            dismissBlock(cover)
        }
        
        cover.dismiss = { [weak cover] in
            guard let cover = cover else {
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
        let transitionAnimator = UIViewPropertyAnimator(duration: AnimationDuration.normalSlow.rawValue, dampingRatio: 1, animations: { [weak self] in
            if style != .alpha {
                self?.view.frame = CGRect(x: 0.0,
                                          y: height,
                                          width: UIScreen.main.bounds.width,
                                          height: UIScreen.main.bounds.height)
            } else {
                self?.view.alpha = 1
            }
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
    
    func dismissModal(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let parent = self.parent,
            let cover = parent.view.viewWithTag(coverViewTag) as? Modal.Cover else {
            return
        }
        //hide
        cover.dismiss?()
        completion?()
    }
}


