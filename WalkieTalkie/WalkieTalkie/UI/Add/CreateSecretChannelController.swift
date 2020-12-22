//
//  CreateSecretChannelController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/5/26.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class CreateSecretChannelController: ViewController {
    enum AlertType {
        case none
        case emptySecretRooms
        case errorPasscode
        case invalid
    }
    
    var container: SecretChannelContainer!
//    var source: Logger.PageShow.Category = .empty
    var joinChannel: (String, Bool) -> Void = { _, _ in }
    var alert: AlertType = .none
    
    static func show(from vc: UIViewController, alert: AlertType = .none, joinChannel: @escaping (String, Bool) -> Void) {
        Logger.logger(Logger.Action.EventName.create_secret_clk.rawValue, alert.loggerCategoryName)
        let controller = CreateSecretChannelController()
        controller.alert = alert
        controller.joinChannel = { name, autoShare in
            //join channels
            joinChannel(name, autoShare)
        }
        controller.showModal(in: vc)
        Logger.UserAction.log(.secret)

    }
    
    deinit {
        cdPrint("[CreateSecretChannelController] deinit")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        container = SecretChannelContainer()
        container.sourceCategory = alert.loggerCategoryName
        view.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(435)
        }
        
        container.viewController = self
        container.update(with: alert)
        container.joinChannel = { [weak self] name, autoShare in
            self?.joinChannel(name, autoShare)
            self?.dismiss()
        }
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                UIView.animate(withDuration: 0) { [weak self] in
                    guard let `self` = self else { return }
                    self.view.top = Frame.Screen.height - self.height() - keyboardVisibleHeight
                }
            })
            .disposed(by: bag)
        
        mainQueueDispatchAsync(after: 0.5) { [weak self] in
            guard let `self` = self,
                self.alert != .none else { return }
            HapticFeedback.Impact.error()
            self.container.alertTitleLabel.shake()
            self.container.alertEmojiLabel.shake()
        }
        
//        Logger.PageShow.logger(Logger.PageShow.EventName.secret_channel_create_pop_imp.rawValue,
//                               alert.loggerCategoryName)
    }
}

extension CreateSecretChannelController {
    func dismiss() {
//        Logger.PageShow.logger(Logger.PageShow.EventName.secret_channel_create_pop_close.rawValue,
//                               alert.loggerCategoryName)
        hideModal()
    }
    
    func shouldDismiss() -> Bool {
        if container.isFirstResponder {
            self.view.endEditing(true)
            return false
        }
        return true
    }
}

extension CreateSecretChannelController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        var alertHeight: CGFloat {
            guard alert != .none, let title = alert.title else {
                return 0
            }
            let titleHeight = title.boundingRect(with: CGSize(width: Frame.Screen.width - 58 - 22, height: 200), font: R.font.nunitoSemiBold(size: 15)!, lineSpacing: 0).height
            return titleHeight + 25 * 2
        }
        let descHeight = R.string.localizable.addChannelSecretTipsDes().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.blackOpsOneRegular(size: 14)!, lineSpacing: 0).height
        let secDescHeight = R.string.localizable.addChannelSecretCreateTipsDes().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.blackOpsOneRegular(size: 14)!, lineSpacing: 0).height
        let contentHeight = 60 + descHeight + 129 + secDescHeight + secDescHeight + 91
        return alertHeight + contentHeight + Frame.Height.safeAeraBottomHeight
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

extension CreateSecretChannelController.AlertType {
    var title: String? {
        switch self {
        case .emptySecretRooms:
            return R.string.localizable.addChannelSecretEmptyJoined()
        case .errorPasscode:
            return R.string.localizable.addChannelSecretErrorPasscode()
        case .invalid:
            return R.string.localizable.addChannelSecretInvalid()
        default:
            return nil
        }
    }
    
    var emoji: String? {
        switch self {
        case .emptySecretRooms, .invalid:
            return "😦"
        case .errorPasscode:
            return "🤔"
        default:
            return nil
        }
    }
    
    var loggerCategoryName: String? {
//        switch self {
//        case .emptySecretRooms:
//            return Logger.PageShow.Category.empty.rawValue
//        case .errorPasscode:
//            return Logger.PageShow.Category.wrong_passcode.rawValue
//        case .invalid:
//            return Logger.PageShow.Category.invaild.rawValue
//        case .none:
//            return Logger.PageShow.Category.normal.rawValue
//        }
        return ""
    }
}

