//
//  Social.EditProfileViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SnapKit

extension Social {
    class EditProfileViewController: ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_back(), for: .normal)
            return btn
        }()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 45
            iv.layer.masksToBounds = true
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onAvatarTapped))
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(tapGR)
            if Config.environment == .debug {
                iv.backgroundColor = UIColor(hex6: 0x0EC099, alpha: 1.0)
            }
            return iv
        }()
        
        private lazy var randomIconIV: UIImageView = {
            let iv = UIImageView()
            iv.image = R.image.profile_avatar_random_btn()
            return iv
        }()
        
        private lazy var userButton: ItemButton = {
            let btn = ItemButton()
            btn.setUserNameData()
            return btn
        }()
        
        private lazy var birthdayButton: ItemButton = {
            let btn = ItemButton()
            btn.setBirthdayData()
            return btn
        }()
        
        private lazy var userInputView = AmongInputNickNameView()
        
        private var profile: Entity.UserProfile!
        
        override var screenName: Logger.Screen.Node.Start {
            return .profile_edit
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            view.endEditing(true)
        }
    }
}
private extension Social.EditProfileViewController {
    func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor.theme(.backgroundBlack)
        view.addSubviews(views: backBtn, avatarIV, randomIconIV, userButton, birthdayButton)
        
        backBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.top.equalToSuperview().offset(16 + Frame.Height.safeAeraTopHeight)
            maker.width.height.equalTo(24)
        }
        
        avatarIV.snp.makeConstraints { (maker) in
            maker.top.equalTo(backBtn.snp.bottom).offset(32.5)
            maker.width.height.equalTo(90)
            maker.centerX.equalToSuperview()
        }
        
        randomIconIV.snp.makeConstraints { (maker) in
            maker.right.bottom.equalTo(avatarIV)
            maker.width.height.equalTo(24)
        }
        
        userButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(avatarIV.snp.bottom).offset(36)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(77)
        }
        
        birthdayButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(userButton.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(77)
        }
        
        view.addSubview(userInputView)
        userInputView.usedInRoom = false
        userInputView.alpha = 0
        userInputView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    
    func setupData() {
        
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        
        Settings.shared.amongChatUserProfile.replay()
            .filterNil()
            .subscribe(onNext: { [weak self] (profile) in
                removeBlock()
                self?.updateFields(profile: profile)
            }, onError: { (_) in
                removeBlock()
            })
            .disposed(by: bag)
        
        userButton.rx.tap
            .subscribe(onNext: { [weak self]() in
                Logger.Action.log(.profile_nikename_clk, category: nil)
                _ = self?.userInputView.becomeFirstResponder()
            }).disposed(by: bag)
        
        birthdayButton.rx.tap
            .subscribe(onNext: { [weak self]() in
                Logger.Action.log(.profile_birthday_clk, category: nil)
                self?.selectBirthday()
            }).disposed(by: bag)
        
        userInputView.inputResultHandler = { [weak self](text) in
            guard let `self` = self else { return }
            let profileProto = Entity.ProfileProto(birthday: nil, name: text, pictureUrl: nil)
            self.updateProfileIfNeeded(profileProto)
        }
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self](height) in
                guard let `self` = self else { return }
                self.userInputView.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-height)
                }
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
            }).disposed(by: bag)
        
        Settings.shared.amongChatAvatarListShown.replay()
            .subscribe(onNext: { [weak self] (ts) in
                if let _ = ts {
                    self?.randomIconIV.redDotOff()
                } else {
                    self?.randomIconIV.redDotOn()
                }
            })
            .disposed(by: bag)

    }
    
    func selectBirthday() {
        let vc = Social.BirthdaySelectViewController()
        vc.onCompletion = { [weak self] (birthdayStr) in
            guard let `self` = self else {
                return
            }
            let profile = Entity.ProfileProto(birthday: birthdayStr, name: nil, pictureUrl: nil)
            self.updateProfileIfNeeded(profile)
        }
        vc.showModal(in: self)
        
        if let b = profile.birthday, !b.isEmpty {
            vc.selectToBirthday(fixBirthdayString(b))
        } else {
            vc.selectToBirthday("")
        }
        view.endEditing(true)
    }
    
    func fixBirthdayString(_ text: String) -> String {
        var b = text
        b.addString("/", at: 4)
        b.addString("/", at: 7)
        return b
    }
    
    func updateFields(profile: Entity.UserProfile) {
        self.profile = profile
        userButton.setRightLabelText(profile.name ?? "")
        if let b = profile.birthday, !b.isEmpty {
            let birthday = self.fixBirthdayString(b)
            birthdayButton.setRightLabelText(birthday)
        } else {
            birthdayButton.setRightLabelText("")
        }
        avatarIV.setAvatarImage(with: profile.pictureUrl)
    }
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
    
    @objc
    func onAvatarTapped() {        
        let vc = Social.SelectAvatarViewController()
        navigationController?.pushViewController(vc)
    }
    
    func updateProfileIfNeeded(_ profileProto: Entity.ProfileProto) {
        if let dict = profileProto.dictionary {
            let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
            Request.updateProfile(dict)
                .do(onDispose: {
                    hudRemoval()
                })
                .subscribe(onSuccess: { (profile) in
                    
                    guard let p = profile else {
                        return
                    }
                    Settings.shared.amongChatUserProfile.value = p
                }, onError: { (error) in
                })
                .disposed(by: bag)
        }
    }
}

private extension Social {
    
    class ItemButton: UIButton {
        
        private lazy var icon = UIImageView()
        
        private lazy var userNameTitle: UILabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var userNameLabel: UILabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.textAlignment = .right
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubviews(views: icon, userNameTitle, userNameLabel)
            
            icon.snp.makeConstraints { (make) in
                make.left.equalTo(20)
                make.top.equalTo(43)
                make.width.height.equalTo(30)
            }
            
            userNameTitle.snp.makeConstraints { (make) in
                make.left.equalTo(icon.snp.right).offset(12)
                make.centerY.equalTo(icon.snp.centerY)
            }
            
            userNameLabel.snp.makeConstraints { (make) in
                make.right.equalTo(-20)
                make.centerY.equalTo(icon.snp.centerY)
            }
        }
        
        func setUserNameData() {
            icon.image = R.image.ac_profile_username()
            userNameTitle.text = R.string.localizable.profileNickname()// "Nickname"
        }
        
        func setBirthdayData() {
            icon.image = R.image.ac_profile_birthday()
            userNameTitle.text = R.string.localizable.profileBirthday()//"Birthday"
        }
        
        func setRightLabelText(_ text: String) {
            userNameLabel.text = text
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class BirthdaySelectViewController: ViewController {
        
        private lazy var birthdayPicker: Social.DatePickerView = {
            let p = Social.DatePickerView(frame: CGRect(x: 0, y: 58, width: Frame.Screen.width, height: 260))
            p.backgroundColor = UIColor(hex6: 0x222222)
            return p
        }()
        
        private lazy var confirmBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            btn.setTitle(R.string.localizable.profileEditSaveBtn(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.appendKern()
            return btn
        }()
        
        var onCompletion: ((String) -> Void)? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor(hex6: 0x222222)
            view.addSubviews(views: birthdayPicker, confirmBtn)
            
            confirmBtn.snp.makeConstraints { (maker) in
                maker.right.equalToSuperview().inset(20)
                maker.top.equalToSuperview().offset(20)
                maker.width.equalTo(77)
                maker.height.equalTo(32)
            }
            
            birthdayPicker.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(confirmBtn.snp.bottom).offset(16)
                maker.height.equalTo(260)
            }
        }
        
        func selectToBirthday(_ text: String) {
            if text.isEmpty {
                birthdayPicker.selectToday()
            } else {
                birthdayPicker.selectBirthday(text)
            }
        }
        
        @objc
        private func onConfirmBtn() {
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd"
            let birthdayStr = df.string(from: birthdayPicker.date)
            dismissModal(animated: true) { [weak self] in
                self?.onCompletion?(birthdayStr)
            }
        }
        
    }
}

extension Social.BirthdaySelectViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 320 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 20
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
