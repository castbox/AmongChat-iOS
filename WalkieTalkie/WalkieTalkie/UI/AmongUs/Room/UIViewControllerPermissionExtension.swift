//
//  UIViewControllerPermissionExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 18/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import AVFoundation
import SDCAlertView
import MessageUI

extension UIViewController {
    /// 获取麦克风权限
    func checkMicroPermission(completion: @escaping ()->()) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] isOpen in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                if !isOpen {
                    self.showAmongAlert(title: R.string.localizable.microphoneNotAllowTitle(), message: R.string.localizable.microphoneNotAllowSubtitle(), cancelTitle: R.string.localizable.toastCancel(), confirmTitle: R.string.localizable.microphoneNotAllowSetting()) {
                        Self.openAppSystemSetting()
                    }
                } else {
                    completion()
                }
            }
        }
    }
    
    static func openAppSystemSetting() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    
    func sendSMS(to number: String? = nil, body: String) {
        if MFMessageComposeViewController.canSendText() {
            let vc = MFMessageComposeViewController()
            vc.recipients = [number ?? ""]
            vc.body = body
            vc.messageComposeDelegate = self
            present(vc, animated: true, completion: nil)
        } else {
            view.raft.autoShow(.text(R.string.localizable.deviceNotSupportSendMessage()))
        }
    }
    
    func showAmongAlert(title: String?, message: String? = nil, cancelTitle: String? = nil, confirmTitle: String? = nil, cancelAction: (() -> Void)? = nil, confirmAction: (() -> Void)? = nil) {
        amongChatAlert(title: title, message: message, cancelTitle: cancelTitle, confirmTitle: confirmTitle, cancelAction: cancelAction, confirmAction: confirmAction).present()
    }
    
    func amongChatAlert(title: String?, message: String? = nil, cancelTitle: String? = nil, confirmTitle: String? = nil, cancelAction: (() -> Void)? = nil, confirmAction: (() -> Void)? = nil) -> AlertController {
        let titleAttr: NSAttributedString?
        if let title = title {
            let attribates: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16),
                .foregroundColor: UIColor.white
            ]
            titleAttr = NSAttributedString(string: title, attributes: attribates)
        } else {
            titleAttr = nil
        }
        
        let messageAttr: NSAttributedString?
        
        if let message = message {
            let attribates: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 15),
                .foregroundColor: UIColor.white
            ]
            messageAttr = NSAttributedString(string: message, attributes: attribates)
        } else {
            messageAttr = nil
        }
        
        let cancelAttr: NSAttributedString?
        if let cancelTitle = cancelTitle {
            let attribates: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16),
                .foregroundColor: "#6C6C6C".color()
            ]
            cancelAttr = NSAttributedString(string: cancelTitle, attributes: attribates)
        } else {
            cancelAttr = nil
        }
        
        //        if let confirmTitle = confirmTitle {
        let attribates: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16),
            .foregroundColor: "#FFF000".color()
        ]
        let confirmAttr = NSAttributedString(string: confirmTitle ?? R.string.localizable.toastConfirm(), attributes: attribates)
        //        } else {
        //            confirmAttr = nil
        //        }
        
        let alertVC = AlertController(attributedTitle: titleAttr, attributedMessage: messageAttr, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        //        visualStyle.but
        alertVC.visualStyle = visualStyle
        //        alertVC.contentView.backgroundColor = "222222".color()
        
        if let cancelAttr = cancelAttr {
            alertVC.addAction(AlertAction(attributedTitle: cancelAttr, style: .normal, handler: { _ in
                cancelAction?()
            }))
        }
        
        alertVC.addAction(AlertAction(attributedTitle: confirmAttr, style: .normal) { _ in
            confirmAction?()
        })
        return alertVC
    }
}

extension UIViewController: MFMessageComposeViewControllerDelegate {
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}
