//
//  CreateGlobalChannelController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/5/26.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class CreateGlobalChannelController: ViewController {
    
    @IBOutlet weak var container: GlobalChannelContainer!

    var joinChannel: (String, Bool) -> Void = { _, _ in }
    private var dismissFromJoinChannel: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        container.joinChannel = { [weak self] name, autoShare in
            self?.joinChannel(name, autoShare)
            self?.dismissFromJoinChannel = true
            self?.dismiss()
        }
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                UIView.animate(withDuration: 0) {
                    self.view.top = Frame.Screen.height - self.height() - keyboardVisibleHeight
                }
            })
            .disposed(by: bag)

    }

    func dismiss() {
//        Logger.PageShow.log(.secret_channel_create_pop_close)
        hideModal()
    }

}

extension CreateGlobalChannelController {
    func shouldDismiss() -> Bool {
        if !dismissFromJoinChannel, container.isFirstResponder {
            self.view.endEditing(true)
            return false
        }
        return true
    }

}

extension CreateGlobalChannelController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
//        let descHeight = R.string.localizable.addChannelSecretTipsDes().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.blackOpsOneRegular(size: 14)!, lineSpacing: 0).height
//        let secDescHeight = R.string.localizable.addChannelSecretCreateTipsDes().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.blackOpsOneRegular(size: 14)!, lineSpacing: 0).height
//        let contentHeight = max(115 + descHeight + 134 + secDescHeight + secDescHeight + 145, 446)
        return 244 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 15
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return shouldDismiss()
    }
}
