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

extension Social {
    class EditProfileViewController: ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.backNor(), for: .normal)
            return btn
        }()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 40
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
            iv.layer.cornerRadius = 15
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
        
        private lazy var userNameInputField: UITextField = {
            let f = UITextField()
            f.contentVerticalAlignment = .center
            f.backgroundColor = .white
            f.font = R.font.nunitoSemiBold(size: 12)
            f.textColor = .black
            f.borderStyle = .none
            f.delegate = self
            let leftMargin = UIView()
            leftMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            let rightMargin = UIView()
            rightMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            f.leftView = leftMargin
            f.rightView = rightMargin
            f.leftViewMode = .always
            f.rightViewMode = .always
            f.cornerRadius = 15
            return f
        }()
        
        private lazy var birthdayTitle: UILabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 12)
            lb.textColor = .black
            lb.text = R.string.localizable.profileEditBirthday()
            lb.appendKern()
            return lb
        }()
        
        private lazy var birthdayInputField: UITextField = {
            let f = UITextField()
            f.contentVerticalAlignment = .center
            f.backgroundColor = .white
            f.font = R.font.nunitoSemiBold(size: 12)
            f.textColor = .black
            f.borderStyle = .none
            f.delegate = self
            let leftMargin = UIView()
            leftMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            let rightMargin = UIView()
            rightMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            f.leftView = leftMargin
            f.rightView = rightMargin
            f.leftViewMode = .always
            f.rightViewMode = .always
            f.cornerRadius = 15
            return f
        }()
        
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
        
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            
            guard parent == nil else {
                return
            }
            
            updateProfileIfNeeded()
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)
            view.addSubviews(views: backBtn, avatarIV, randomIconIV, userNameTitle, userNameInputField, birthdayTitle, birthdayInputField)
            
            backBtn.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(15)
                maker.top.equalTo(topLayoutGuide.snp.bottom).offset(11.5)
                maker.width.height.equalTo(25)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(topLayoutGuide.snp.bottom).offset(16)
                maker.width.height.equalTo(80)
                maker.centerX.equalToSuperview()
            }
            
            randomIconIV.snp.makeConstraints { (maker) in
                maker.right.bottom.equalTo(avatarIV)
                maker.width.height.equalTo(30)
            }
            
            userNameTitle.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(44.5)
                maker.left.equalToSuperview().offset(29)
                maker.height.equalTo(16.5)
            }
            
            userNameInputField.snp.makeConstraints { (maker) in
                maker.top.equalTo(userNameTitle.snp.bottom).offset(16)
                maker.left.right.equalToSuperview().inset(29)
                maker.height.equalTo(50)
            }
            
            birthdayTitle.snp.makeConstraints { (maker) in
                maker.left.height.equalTo(userNameTitle)
                maker.top.equalTo(userNameInputField.snp.bottom).offset(23)
            }
            
            birthdayInputField.snp.makeConstraints { (maker) in
                maker.left.right.height.equalTo(userNameInputField)
                maker.top.equalTo(birthdayTitle.snp.bottom).offset(16)
            }
            
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
            
        }
        
        private func updateFields() {
            userNameInputField.text = profile.name
            birthdayInputField.text = profile.birthday
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
        private func onAvatarTapped() {
            let avatar = FireStore.Entity.User.Profile.randomDefaultAvatar()
            avatarIV.image = avatar.0
            profile.avatar = "\(avatar.1)"
        }
        
        private func updateProfileIfNeeded() {
            profile.name = userNameInputField.text?.trim() ?? Constants.defaultUsername
            profile.birthday = birthdayInputField.text ?? ""
            
            let currentProfile = Settings.shared.firestoreUserProfile.value
            
            if profile.name != currentProfile?.name ||
                profile.avatar != currentProfile?.avatar ||
                profile.birthday != currentProfile?.birthday {
                Settings.shared.firestoreUserProfile.value = profile
            }
        }
        
    }
}

extension Social.EditProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == birthdayInputField {
            let vc = Social.BirthdaySelectViewController()
            vc.onCompletion = { [weak self] (birthdayStr) in
                self?.birthdayInputField.text = birthdayStr
            }
            vc.showModal(in: self)
            view.endEditing(true)
            return false
        } else {
            return true
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard textField == userNameInputField else {
            return true
        }
        
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 20
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == userNameInputField {
            birthdayInputField.becomeFirstResponder()
        }
        
        return false
    }
    
}

extension Social {
    
    class BirthdaySelectViewController: ViewController {
        
        private lazy var birthdayPicker: UIDatePicker = {
            let p = UIDatePicker()
            p.datePickerMode = .date
            p.date = Date()
            p.maximumDate = Date()
            p.minimumDate = Date(timeIntervalSince1970: 0)
            return p
        }()
        
        private lazy var confirmBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            btn.setTitle("Done", for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        var onCompletion: ((String) -> Void)? = nil

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .white
            view.addSubviews(views: birthdayPicker, confirmBtn)

            confirmBtn.snp.makeConstraints { (maker) in
                maker.right.equalToSuperview().inset(15)
                maker.top.equalTo(topLayoutGuide.snp.bottom).offset(10)
                maker.width.equalTo(80)
                maker.height.equalTo(30)
            }
            
            birthdayPicker.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(confirmBtn.snp.bottom).offset(10)
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
        return 300 + Frame.Height.safeAeraBottomHeight
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
