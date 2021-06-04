//
//  CopyableLabel.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CopyableLabel: UILabel {
    
    private (set) var longPressGesture: UILongPressGestureRecognizer!
    
    private let bag = DisposeBag()
    
    var tapHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }
    
    func sharedInit() {
        self.isUserInteractionEnabled = true
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showMenu))
        self.addGestureRecognizer(longPressGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tapGesture.require(toFail: longPressGesture)
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapAction() {
        tapHandler?()
    }
    
    @objc func showMenu(_ recognizer: UILongPressGestureRecognizer) {
        self.becomeFirstResponder()
        
        let menu = UIMenuController.shared
        
        let locationOfTouchInLabel = recognizer.location(in: self)

        if !menu.isMenuVisible {
            var rect = bounds
            rect.size = CGSize(width: 1, height: 1)
            rect.origin.y = 0
            rect.origin.x = bounds.midX
            
            menu.setTargetRect(rect, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        
        board.string = text
        
        let menu = UIMenuController.shared
        
        menu.setMenuVisible(false, animated: true)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}
