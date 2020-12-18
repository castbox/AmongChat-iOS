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
            btn.setImage(R.image.ac_profile_back(), for: .normal)
            return btn
        }()
        
        private lazy var saveBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoBold(size: 16)
            btn.setTitleColor(UIColor.white, for: .normal)
            btn.setTitle(R.string.localizable.profileEditSaveBtn(), for: .normal)
            btn.addTarget(self, action: #selector(onSaveBtn), for: .primaryActionTriggered)
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
        
        private lazy var userNameTitle: UILabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 12)
            lb.text = R.string.localizable.profileEditUsername()
            lb.textColor = .black
            lb.appendKern()
            return lb
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
            let f = UITextField()
//            f.clearButtonMode = .always
//            f.keyboardType = .alphabet
//            f.contentVerticalAlignment = .center
//            f.backgroundColor = .white
//            f.font = R.font.nunitoSemiBold(size: 12)
//            f.textColor = .black
//            f.borderStyle = .none
//            f.delegate = self
//            let leftMargin = UIView()
//            leftMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
//            let rightMargin = UIView()
//            rightMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
//            f.leftView = leftMargin
//            f.rightView = rightMargin
//            f.leftViewMode = .always
//            f.cornerRadius = 15
//            f.addTarget(self, action: #selector(onTextFieldDidChange), for: .editingChanged)
            f.isHidden = true
            return f
        }()
        
        private lazy var birthdayTitle: UILabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 12)
            lb.textColor = .black
            lb.text = R.string.localizable.profileEditBirthday()
            lb.appendKern()
            lb.isHidden = true
            return lb
        }()
        
        private lazy var birthdayInputField: UITextField = {
            let f = UITextField()
//            f.contentVerticalAlignment = .center
//            f.backgroundColor = .white
//            f.font = R.font.nunitoSemiBold(size: 12)
//            f.textColor = .black
//            f.borderStyle = .none
//            f.delegate = self
//            let leftMargin = UIView()
//            leftMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
//            let rightMargin = UIView()
//            rightMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
//            f.leftView = leftMargin
//            f.rightView = rightMargin
//            f.leftViewMode = .always
//            f.rightViewMode = .always
//            f.cornerRadius = 15
//            f.isHidden = true
            return f
        }()
        private lazy var userInputView = UserNameInputView()
        private var profile: FireStore.Entity.User.Profile = FireStore.Entity.User.Profile(avatar: "", birthday: "", name: Constants.defaultUsername, premium: false, uidInt: Constants.sUserId, uid: "")
        
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
                maker.top.equalToSuperview().offset(56 - Frame.Height.safeAeraTopHeight)
                maker.width.height.equalTo(25)
            }
        
             avatarIV.snp.makeConstraints { (maker) in
                 maker.top.equalToSuperview().offset(113 - Frame.Height.safeAeraTopHeight)
                 maker.width.height.equalTo(90)
                 maker.centerX.equalToSuperview()
             }
             
             randomIconIV.snp.makeConstraints { (maker) in
                 maker.right.bottom.equalTo(avatarIV)
                 maker.width.height.equalTo(24)
             }
            
            userButton.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(-10)
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
            
            Settings.shared.firestoreUserProfile.replay()
                .filterNil()
                .take(1)
                .timeout(.seconds(5), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (profile) in
                    removeBlock()
                    self?.profile = profile
                    self?.updateFields()
                }, onError: { [weak self] (_) in
                    removeBlock()
                    self?.updateFields()
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
                    self.profile.name = text
                    self.userButton.setRightLabelText(text)
                    self.updateProfileIfNeeded()
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
            guard Date().timeIntervalSince(Date(timeIntervalSince1970: Defaults[\.socialBirthdayUpdateAtTsKey])) > 24 * 60 * 60 * 7 else {
                view.raft.autoShow(.text(R.string.localizable.profielEditBirthdayCantTip()), interval: 2, userInteractionEnabled: false)
                return
            }
            let vc = Social.BirthdaySelectViewController()
            vc.onCompletion = { [weak self] (birthdayStr) in
                self?.birthdayButton.setRightLabelText(birthdayStr)
                self?.profile.birthday = birthdayStr
                self?.updateProfileIfNeeded()
            }
            vc.showModal(in: self)
            view.endEditing(true)
        }
        
        private func updateFields() {
            userButton.setRightLabelText(profile.name)
            birthdayButton.setRightLabelText(profile.birthday)
            
            let _ = profile.avatarObservable
                .subscribe(onSuccess: { [weak self] (image) in
                    self?.avatarIV.image = image
            })
        }
        
        @objc
        private func onBackBtn() {
            navigationController?.popViewController()
        }
        
        @objc
        private func onSaveBtn() {
            view.endEditing(true)
            updateProfileIfNeeded()
            navigationController?.popViewController()
        }
        
        @objc
        private func onAvatarTapped() {
            // avatar_change log
            GuruAnalytics.log(event: "avatar_change", category: nil, name: nil, value: nil, content: nil)
            //
            let avatar = FireStore.Entity.User.Profile.randomDefaultAvatar()
            avatarIV.image = avatar.0
            profile.avatar = "\(avatar.1)"
            updateProfileIfNeeded()
        }
        
        @objc
        private func onTextFieldDidChange() {
            let name: String = userNameInputField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            saveBtn.alpha = name.isEmpty ? 0.5 : 1.0
            saveBtn.isEnabled = !name.isEmpty
        }
        
        private func updateProfileIfNeeded() {
            let currentProfile = Settings.shared.firestoreUserProfile.value
            
            if profile.name != currentProfile?.name ||
                profile.avatar != currentProfile?.avatar ||
                profile.birthday != currentProfile?.birthday {
                
                if profile.birthday != currentProfile?.birthday {
                    Defaults[\.socialBirthdayUpdateAtTsKey] = Date().timeIntervalSince1970
                }
                
                Settings.shared.firestoreUserProfile.value = profile
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
            userNameTitle.text = "Nickname"
        }
        
        func setBirthdayData() {
            icon.image = R.image.ac_profile_birthday()
            userNameTitle.text = "Birthday"
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
            btn.setTitle("Save", for: .normal)
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
            birthdayPicker.selectToday()
        }
        
        @objc
        private func onConfirmBtn() {
            let birthdayStr = birthdayPicker.selectedDate
            dismissModal(animated: true) { [weak self] in
                self?.onCompletion?(birthdayStr)
            }
        }
        
    }
    
    class UserNameInputView: UIView, UITextFieldDelegate {
        
        var doneHandle:((_ text: String) -> Void)?
        
        private lazy var textFiled: UITextField = {
            let f = UITextField()
            f.clearButtonMode = .always
            f.keyboardType = .alphabet
            f.contentVerticalAlignment = .center
            f.backgroundColor = .white
            f.font = R.font.nunitoExtraBold(size: 20)
            f.textColor = .black
            f.textAlignment = .center
            f.borderStyle = .none
            f.delegate = self
            f.leftViewMode = .always
            f.attributedPlaceholder = NSAttributedString(string: "NICKNAME", attributes: [NSAttributedString.Key.foregroundColor: UIColor(hex6: 0xD8D8D8), NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16)])
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
            btn.setTitle("Done", for: .normal)
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
                make.right.equalTo(-20)
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
