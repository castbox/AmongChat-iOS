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
import AppTrackingTransparency
import RxSwift
import RxCocoa

extension UIViewController {
    /// 获取麦克风权限
    func checkMicroPermission(title: String? = R.string.localizable.microphoneNotAllowTitle(), message: String? = R.string.localizable.microphoneNotAllowSubtitle(), completion: @escaping ()->()) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] isOpen in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                if !isOpen {
                    self.showAmongAlert(title: title, message: message, cancelTitle: R.string.localizable.toastCancel(), confirmTitle: R.string.localizable.microphoneNotAllowSetting()) {
                        Self.openAppSystemSetting()
                    }
                } else {
                    completion()
                }
            }
        }
    }
    
    //FOR APP TRACKING
    func requestAppTrackPermission() -> Single<Void> {
        return Single.create { [weak self] observer in
            self?.requestAppTrackPermission(completion: {
                observer(.success(()))
            })
            return Disposables.create {
                
            }
        }
    }
    func requestAppTrackPermission(completion: CallBack?) {
        guard let viewController = self as? ViewController else {
            completion?()
            return
        }
        PermissionManager.shared.request(permission: .appTracking, on: viewController, completion: completion)
        
//        if #available(iOS 14.0, *) {
//            cdPrint("attrackingAuthorization state: \(ATTrackingManager.trackingAuthorizationStatus.rawValue)")
//            switch ATTrackingManager.trackingAuthorizationStatus {
//            case .authorized:
//                completion?()
//            case .denied, .restricted:
//                completion?()
//            case .notDetermined:
//                showAppTrackPermissionPreRequestAlert(with: completion)
//            @unknown default:
//                completion?()
//            }
//        } else {
//            completion?()
//        }
    }
    
    @available(iOS 14, *)
    private func showAppTrackPermissionPreRequestAlert(with completionHandler: CallBack?) {
        
        Logger.Action.log(.space_card_tip_clk)
        
        let alert = amongChatAlert(title: nil, confirmTitle: R.string.localizable.toastConfirm())
        let content = AppTrackingGuideView()
        alert.contentView.addSubview(content)
        content.allowTrackingHandler = { [weak self] in
            ATTrackingManager.requestTrackingAuthorization { status in
                cdPrint("requestTrackingAuthorization result state: \(status.rawValue)")
                mainQueueDispatchAsync(after: 0.1) {
                    completionHandler?()
                }
            }
        }
        content.laterHandler = { [weak self] in
            completionHandler?()
        }
        content.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
//        decorateAlert(alert)
        var hPadding: CGFloat = 28
        adaptToIPad {
            hPadding = 190
        }
        alert.visualStyle.width = Frame.Screen.width - hPadding * 2
        alert.visualStyle.verticalElementSpacing = 0
        alert.visualStyle.contentPadding = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        alert.visualStyle.actionViewSize = CGSize(width: 0, height: 49)
        alert.view.backgroundColor = UIColor.black.alpha(0.6)
        alert.present()
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
    
    func openTiktok() {
        guard let url = URL(string: "https://www.tiktok.com/tag/amongchat") else {
            return
        }
        UIApplication.shared.open(url, options: [:]) { _ in
            
        }
    }
    
    func showAmongAlert(title: String?, message: String? = nil, cancelTitle: String? = nil, confirmTitle: String? = nil, confirmTitleColor: UIColor? = nil, cancelAction: (() -> Void)? = nil, confirmAction: (() -> Void)? = nil) {
        amongChatAlert(title: title, message: message, cancelTitle: cancelTitle, confirmTitle: confirmTitle, confirmTitleColor: confirmTitleColor, cancelAction: cancelAction, confirmAction: confirmAction).present()
    }
    
    @discardableResult
    func amongChatAlert(title: String?, message: String? = nil, cancelTitle: String? = nil, confirmTitle: String? = nil, confirmTitleColor: UIColor? = nil, cancelAction: (() -> Void)? = nil, confirmAction: (() -> Void)? = nil) -> AlertController {
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
            .foregroundColor: confirmTitleColor ?? "#FFF000".color()
        ]
        let confirmAttr = NSAttributedString(string: confirmTitle ?? R.string.localizable.toastConfirm(), attributes: attribates)
        //        } else {
        //            confirmAttr = nil
        //        }
        
        let alertVC = AlertController(attributedTitle: titleAttr, attributedMessage: messageAttr, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.contentPadding = UIEdgeInsets(top: 36, left: 32, bottom: 28, right: 32)
//        visualStyle.verticalElementSpacing = 40
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.06)
        visualStyle.actionViewSeparatorThickness = 1
        visualStyle.actionViewSize = CGSize(width: 0, height: 49)
        visualStyle.width = UIScreen.main.bounds.width - 28 * 2
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
        
        let _ = alertVC.rx.viewWillAppear.take(1)
            .subscribe(onNext: { [weak alertVC]_ in
                alertVC?.view.backgroundColor = UIColor.black.alpha(0.7)
            })

        return alertVC
    }
}

extension UIViewController: MFMessageComposeViewControllerDelegate {
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}
