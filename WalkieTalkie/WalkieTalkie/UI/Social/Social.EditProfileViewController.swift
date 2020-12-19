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
            #if DEBUG
            iv.backgroundColor = UIColor(hex6: 0x0EC099, alpha: 1.0)
            #endif
            return iv
        }()
        
        private lazy var randomIconIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 12
            iv.layer.masksToBounds = true
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
        
        private lazy var userNameInputField: UITextField = {
            let textFiled = UITextField()
            textFiled.isHidden = true
            return textFiled
        }()
        
        private lazy var userInputView = UserNameInputView()
        private var profile: Entity.UserProfile!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            view.endEditing(true)
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            statusBarStyle = .lightContent
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            view.addSubviews(views: backBtn, avatarIV, randomIconIV, userButton, birthdayButton)
            
            backBtn.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(15)
                maker.top.equalToSuperview().offset(16 + Frame.Height.safeAeraTopHeight)
                maker.width.height.equalTo(25)
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
            userButton.addSubview(userNameInputField)
            userNameInputField.snp.makeConstraints { (make) in
                make.right.equalTo(-20)
            }
            
            userInputView.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 520)
            userInputView.isHidden = true
            view.addSubview(userInputView)
        }
        
        private func setupData() {
                        
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
                    self?.userNameInputField.becomeFirstResponder()
                }).disposed(by: bag)
            
            birthdayButton.rx.tap
                .subscribe(onNext: { [weak self]() in
                    self?.selectBirthday()
                }).disposed(by: bag)
            
            userInputView.doneHandle = { [weak self](text) in
                guard let `self` = self else { return }
                if !text.isEmpty {
                    let profileProto = Entity.ProfileProto(birthday: nil, name: text, pictureUrl: nil)
                    self.updateProfileIfNeeded(profileProto)
                }
            }
            
            RxKeyboard.instance.isHidden
                .drive(onNext: { [weak self](hidden) in
                    self?.userInputView.isHidden = hidden
                    if !hidden {
                        self?.userInputView.becomeActive()
                    }
                }).disposed(by: bag)
            
            RxKeyboard.instance.visibleHeight
                .drive(onNext: { [weak self](height) in
                    guard let `self` = self else { return }
                    UIView.animate(withDuration: 0) {
                        self.userInputView.bottom = Frame.Screen.height - height
                        self.view.layoutIfNeeded()
                    }
                }).disposed(by: bag)
        }
        
        func selectBirthday() {
            //let vc = Social.BirthdaySetViewController()
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
        
        private func fixBirthdayString(_ text: String) -> String {
            var b = text
            let index = b.index(b.startIndex, offsetBy: 4)
            b.insert("/", at: index)
            
            let index1 = b.index(b.startIndex, offsetBy: 7)
            b.insert("/", at: index1)
            return b
        }
        
        private func updateFields(profile: Entity.UserProfile) {
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
        private func onBackBtn() {
            navigationController?.popViewController()
        }
        
        @objc
        private func onAvatarTapped() {
            guard let avatar = Settings.shared.amongChatDefaultAvatars.value?.randomAvatar else {
                return
            }
            
            let profileProto = Entity.ProfileProto(birthday: nil, name: nil, pictureUrl: avatar)
            updateProfileIfNeeded(profileProto)
        }
        
        private func updateProfileIfNeeded(_ profileProto: Entity.ProfileProto) {
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
            let p = Social.DatePickerView(frame: CGRect(x: 0, y: 58, width: Frame.Screen.width - 80, height: 260))
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
    
    class UserNameInputView: UIView, UITextFieldDelegate {
        
        var doneHandle:((_ text: String) -> Void)?
        
        private lazy var textFiled: UITextField = {
            let f = UITextField()
//            f.clearButtonMode = .always
            f.keyboardType = .alphabet
            f.contentVerticalAlignment = .center
            f.backgroundColor = .white
            f.font = R.font.nunitoExtraBold(size: 20)
            f.textColor = .black
            f.textAlignment = .center
            f.borderStyle = .none
            f.delegate = self
            f.leftViewMode = .always
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            f.attributedPlaceholder = NSAttributedString(string: R.string.localizable.profileBagNickname(), attributes: [NSAttributedString.Key.foregroundColor: UIColor(hex6: 0xD8D8D8), NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16), NSAttributedString.Key.paragraphStyle: style])
            return f
        }()
        
        private lazy var cancelBtn: UIButton = {
            let btn = UIButton()
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.toastCancel(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            return btn
        }()
        
        private lazy var doneBtn: UIButton = {
            let btn = UIButton()
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.profileDone(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            return btn
        }()
        
        let bag = DisposeBag()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .clear
            
            let backView = UIView()
            backView.alpha = 0.7
            backView.backgroundColor = .black
            addSubview(backView)
            backView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            let bottoView = UIView()
            bottoView.backgroundColor = .black
            addSubview(bottoView)
            bottoView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(127)
            }
            
            let contentView = UIView()
            contentView.backgroundColor = .white
            bottoView.addSubview(contentView)
            contentView.layer.masksToBounds = true
            contentView.layer.cornerRadius = 24
            contentView.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.left.equalTo(40)
                make.right.equalTo(-40)
                make.height.equalTo(48)
            }
            
            contentView.addSubview(textFiled)
            textFiled.snp.makeConstraints { (make) in
                make.left.equalTo(24)
                make.right.equalTo(-24)
                make.centerY.equalToSuperview()
            }
            
            bottoView.addSubview(cancelBtn)
            cancelBtn.snp.makeConstraints { (make) in
                make.left.equalTo(40)
                make.top.equalTo(contentView.snp.bottom).offset(20)
            }
            
            bottoView.addSubview(doneBtn)
            doneBtn.snp.makeConstraints { (make) in
                make.right.equalTo(-40)
                make.top.equalTo(contentView.snp.bottom).offset(20)
            }
            addEvents()
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func addEvents() {
            cancelBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.hidden()
                }).disposed(by: bag)
            
            doneBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    self.doneHandle?(self.textFiled.text ?? "")
                    self.hidden()
                }).disposed(by: bag)
        }
        
        func hidden() {
            textFiled.resignFirstResponder()
        }
        
        func becomeActive() {
            textFiled.becomeFirstResponder()
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            
            let set = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789").inverted
            let filteredString = string.components(separatedBy: set).joined(separator: "")
            
            let currentCharacterCount = textField.text?.count ?? 0
            if range.length + range.location > currentCharacterCount {
                return false
            }
            let newLength = currentCharacterCount + string.count - range.length
            return (filteredString == string && newLength <= 10) || newLength < currentCharacterCount
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
        return 6
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
