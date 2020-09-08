//
//  Social.InitialProfileViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

extension Social {
    
    class InitialProfileViewController: ViewController {
                
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onAvatarTapped))
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(tapGR)
            iv.layer.cornerRadius = 45
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var randomIcon: UIImageView = {
            let iv = UIImageView()
            #if DEBUG
            iv.backgroundColor = .gray
            #endif
            iv.layer.cornerRadius = 15
            iv.layer.masksToBounds = true
            iv.image = R.image.profile_avatar_random_btn()
            return iv
        }()
        
        private lazy var nameInputField: UITextField = {
            let f = UITextField()
            f.textAlignment = .right
            f.font = R.font.nunitoSemiBold(size: 12)
            f.textColor = .black
            f.borderStyle = .none
            f.delegate = self
            return f
        }()
        
        private lazy var nameInputLabel: UILabel = {
            let label = WalkieLabel()
            label.text = R.string.localizable.profileInitialUserNameTitle()
            label.font = R.font.nunitoRegular(size: 12)
            label.textColor = UIColor(hex6: 0x000000, alpha: 0.5)
            label.appendKern()
            return label
        }()
        
        private lazy var nameInputContainer: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(hex6: 0xFAFAFA, alpha: 1.0)
            view.layer.borderColor = UIColor(hex6: 0x979797, alpha: 1.0).cgColor
            view.layer.borderWidth = 0.5
            view.layer.cornerRadius = 8
            return view
        }()
        
        private lazy var tipLabel: UILabel = {
            let lb = WalkieLabel()
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.font = R.font.nunitoRegular(size: 14)
            lb.textColor = .black
            lb.text = R.string.localizable.profileInitialTip()
            lb.appendKern()
            return lb
        }()
        
        private lazy var confirmBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.profileInitialConfirmBtn(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        private lazy var bgView: UIView = {
            let v = UIView()
            v.backgroundColor = .white
            return v
        }()
        
        private lazy var avatar: (UIImage?, Int) = FireStore.Entity.User.Profile.randomDefaultAvatar()
        
        var onDismissHandler: (() -> Void)? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            setupEvent()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            bgView.addCorner(with: 6)
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            view.endEditing(true)
        }
        
        private func setupLayout() {
            view.backgroundColor = .clear
            nameInputContainer.addSubviews(views: nameInputLabel, nameInputField)
            nameInputLabel.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().inset(16.5)
                maker.centerY.equalToSuperview()
            }
            
            nameInputField.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().inset(17.5)
                maker.left.equalTo(nameInputLabel.snp.right).offset(10)
            }
            
            view.addSubviews(views: bgView, avatarIV, randomIcon, nameInputContainer, tipLabel, confirmBtn)
            
            bgView.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.top.equalTo(30)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.centerX.equalToSuperview()
                maker.size.equalTo(CGSize(width: 90, height: 90))
            }
            
            randomIcon.snp.makeConstraints { (maker) in
                maker.right.bottom.equalTo(avatarIV)
                maker.size.equalTo(CGSize(width: 30, height: 30))
            }
            
            nameInputContainer.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.size.equalTo(CGSize(width: 271, height: 40))
                maker.top.equalTo(avatarIV.snp.bottom).offset(25)
            }
            
            tipLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameInputContainer.snp.bottom).offset(15)
                maker.left.right.equalToSuperview().inset(25)
            }
            
            confirmBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameInputContainer.snp.bottom).offset(74)
                maker.size.equalTo(CGSize(width: 225, height: 48))
                maker.centerX.equalToSuperview()
            }
            
        }
        
        private func setupData() {
            avatarIV.image = avatar.0
            guard let profile = Settings.shared.firestoreUserProfile.value else {
                nameInputField.text = Constants.defaultUsername
                return
            }
            nameInputField.text = profile.name
        }
        
        private func setupEvent() {
            
            RxKeyboard.instance.visibleHeight
                .drive(onNext: { [weak self] keyboardVisibleHeight in
                    guard let `self` = self else { return }
                    UIView.animate(withDuration: 0) {
                        self.view.top = Frame.Screen.height - self.height() - keyboardVisibleHeight
                    }
                })
                .disposed(by: bag)
            
            rx.viewDidAppear
                .take(1)
                .subscribe(onNext: { (_) in
                    Defaults[\.profileInitialShownTsKey] = Date().timeIntervalSince1970
                })
                .disposed(by: bag)
        }
        
        @objc
        private func onConfirmBtn() {
            
            defer {
                dismissModal(animated: true) {[weak self] in
                    self?.onDismissHandler?()
                }
            }
            
            guard var profile = Settings.shared.firestoreUserProfile.value else {
                return
            }
            
            profile.name = nameInputField.text?.trim() ?? Constants.defaultUsername
            profile.avatar = "\(avatar.1)"
            Settings.shared.firestoreUserProfile.value = profile
        }
        
        @objc
        private func onAvatarTapped() {
            avatar = FireStore.Entity.User.Profile.randomDefaultAvatar()
            avatarIV.image = avatar.0
        }
        
    }
}

extension Social.InitialProfileViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 20
    }
    
}

extension Social.InitialProfileViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 317 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 6
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        view.endEditing(true)
        return false
    }
}
