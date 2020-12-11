//
//  AmongChat.Home.JoinSecretViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class JoinSecretViewController: WalkieTalkie.ViewController {
        
        // MARK: -

        private lazy var bgTapGr: UITapGestureRecognizer = {
            let gr = UITapGestureRecognizer(target: self, action: #selector(onBgTapped))
            return gr
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let l = WalkieLabel(text: R.string.localizable.joinChannelSecretTipsTitle())
            l.font = R.font.nunitoBold(size: 20)
            l.numberOfLines = 0
            l.lineBreakMode = .byWordWrapping
            return l
        }()
        
        private lazy var describeLabel: WalkieLabel = {
            let l = WalkieLabel(text: R.string.localizable.addChannelSecretTipsDes())
            l.font = R.font.nunitoSemiBold(size: 14)
            l.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            l.numberOfLines = 0
            l.lineBreakMode = .byWordWrapping
            return l
        }()
        
        private lazy var channelFieldContainer: UIView = {
            let v = UIView()
            v.layer.borderWidth = 1
            v.layer.cornerRadius = 10
            v.layer.borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1).cgColor
            
            v.addSubviews(views: codeField, confirmButton)
            
            codeField.snp.makeConstraints { (maker) in
                maker.leading.equalTo(15)
                maker.top.bottom.equalToSuperview()
            }
            
            confirmButton.snp.makeConstraints { (maker) in
                maker.leading.equalTo(codeField.snp.trailing)
                maker.top.bottom.trailing.equalToSuperview()
            }
            
            return v
        }()
        
        private lazy var codeField: ChannelNameField = {
            let f = ChannelNameField()
            f.clearButtonMode = .never
            f.placeholder = "PASSCODE"
            f.font = R.font.nunitoBold(size: 17)
            f.keyboardType = .asciiCapable
            f.autocapitalizationType = .allCharacters
            return f
        }()
        
        private lazy var confirmButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.icon_pri_join(), for: .normal)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        var joinChannel: (String, Bool) -> Void = { _, _ in }
        
        // MARK: -
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvents()
        }
        
    }
    
}

extension AmongChat.Home.JoinSecretViewController {
    
    @objc
    private func onBgTapped() {
        view.endEditing(true)
    }
    
    @objc
    private func onConfirmBtn() {
        guard let name = codeField.text?.uppercased() else {
            return
        }
        
        let joinBlock = { [weak self] in
            guard let `self` = self else { return }
            _ = self.codeField.resignFirstResponder()
            self.joinChannel(name, false)
            self.dismiss()
        }
        
        joinBlock()
    }
}

extension AmongChat.Home.JoinSecretViewController {
    
    private func setupLayout() {
        
        view.backgroundColor = .white
        
        view.addSubviews(views: titleLabel, describeLabel, channelFieldContainer)
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(25)
            maker.trailing.lessThanOrEqualToSuperview().offset(-25)
            maker.top.equalToSuperview().offset(30)
        }
        
        describeLabel.snp.makeConstraints { (maker) in
            maker.leading.equalTo(titleLabel)
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
        
        channelFieldContainer.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(25)
            maker.trailing.equalToSuperview().offset(-25)
            maker.height.equalTo(50)
            maker.top.equalTo(describeLabel.snp.bottom).offset(20)
        }
        
        view.addGestureRecognizer(bgTapGr)
    }
    
    private func setupEvents() {
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                UIView.animate(withDuration: 0) { [weak self] in
                    guard let `self` = self else { return }
                    self.view.top = Frame.Screen.height - self.height() - keyboardVisibleHeight
                }
            })
            .disposed(by: bag)
        
    }
    
    private func dismiss() {
        hideModal()
    }
    
    private func shouldDismiss() -> Bool {
        if codeField.isFirstResponder {
            self.view.endEditing(true)
            return false
        }
        return true
    }
}

extension AmongChat.Home.JoinSecretViewController: Modalable {
    
    // MARK: - Modalable
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        let titleLabelHeight = R.string.localizable.joinChannelSecretTipsTitle().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.nunitoBold(size: 20)!, lineSpacing: 0).height
        let descHeight = R.string.localizable.addChannelSecretTipsDes().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.nunitoSemiBold(size: 14)!, lineSpacing: 0).height
        let contentHeight = 30 + titleLabelHeight + 4 + descHeight + 20 + 50 + 30
        return contentHeight + Frame.Height.safeAeraBottomHeight
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
