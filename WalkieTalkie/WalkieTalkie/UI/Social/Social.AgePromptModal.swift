//
//  Social.AgePromptModal.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/16.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

extension Social {
    
    class AgePromptModal: WalkieTalkie.ViewController {
        
        var topicId: String?
        
        private lazy var promptView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.layer.cornerRadius = 12
            
            let closeBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.setImage(R.image.ac_age_prompt_close(), for: .normal)
                btn.addTarget(self, action: #selector(onCloseBtn), for: .primaryActionTriggered)
                return btn
            }()
            
            let icon: UIImageView = {
                let i = UIImageView(image: R.image.ac_age_prompt_icon())
                return i
            }()
            
            let titleLabel: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoExtraBold(size: 20)
                lb.textColor = .white
                lb.text = R.string.localizable.amongChatAgePromptTitle()
                lb.textAlignment = .center
                lb.adjustsFontSizeToFitWidth = true
                return lb
            }()
            
            let msgLabel: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoExtraBold(size: 14)
                lb.textColor = UIColor(hex6: 0xABABAB)
                lb.numberOfLines = 4
                lb.textAlignment = .center
                lb.adjustsFontSizeToFitWidth = true
                lb.text = R.string.localizable.amongChatAgePromptMsg()
                return lb
            }()
            
            let goBtn: UIButton = {
                let btn = UIButton()
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                btn.setTitleColor(UIColor.black, for: .normal)
                btn.setTitle(R.string.localizable.bigGo().uppercased(), for: .normal)
                btn.backgroundColor = UIColor(hex6: 0xFFF000)
                btn.layer.masksToBounds = true
                btn.layer.cornerRadius = 24
                btn.addTarget(self, action: #selector(onGoBtn), for: .primaryActionTriggered)
                return btn
            }()
            
            v.addSubviews(views: closeBtn, icon, titleLabel, msgLabel, goBtn)
            
            closeBtn.snp.makeConstraints { (maker) in
                maker.trailing.top.equalToSuperview().inset(20)
                maker.width.height.equalTo(20)
            }
            
            icon.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(130)
                maker.centerX.equalToSuperview()
                maker.top.equalTo(40)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(icon.snp.bottom).offset(28)
                maker.height.equalTo(27)
            }
            
            msgLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(titleLabel.snp.bottom).offset(8)
            }
            
            goBtn.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(48)
                maker.top.equalTo(msgLabel.snp.bottom).offset(40)
                maker.bottom.equalToSuperview().inset(40)
            }
            
            return v
        }()
        
        private lazy var setAgeView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.addSubviews(views: birthdayPicker, closeBtn, saveBtn)
            
            birthdayPicker.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(30)
                maker.top.equalToSuperview().inset(40)
            }
            
            closeBtn.snp.makeConstraints { (maker) in
                maker.top.trailing.equalToSuperview().inset(10)
                maker.width.height.equalTo(40)
            }
            
            saveBtn.snp.makeConstraints { (maker) in
                maker.left.equalTo(30)
                maker.right.equalTo(-30)
                maker.height.equalTo(48)
                maker.bottom.equalTo(-47 - Frame.Height.safeAeraBottomHeight)
            }

            return v
        }()
        
        private lazy var birthdayPicker: UIPickerView = {
            let p = UIPickerView()
            p.backgroundColor = UIColor(hex6: 0x222222)
            p.dataSource = self
            p.delegate = self
            return p
        }()
        
        private lazy var saveBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoBlack(size: 20)
            btn.addTarget(self, action: #selector(onSaveBtn), for: .primaryActionTriggered)
            btn.setTitle(R.string.localizable.profileDone(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.backgroundColor = UIColor(hex6: 0x2B2B2B)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 24
            btn.isEnabled = false
            return btn
        }()
        
        private lazy var closeBtn: UIButton = {
            let btn = UIButton(type: .custom)
//            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.addTarget(self, action: #selector(onCloseBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_age_prompt_close(), for: .normal)
//            btn.setTitle(R.string.localizable.profileEditSaveBtn(), for: .normal)
//            btn.setTitleColor(.black, for: .normal)
//            btn.isEnabled = false
//            btn.backgroundColor = UIColor(hex6: 0xFFF000)
//            btn.layer.masksToBounds = true
//            btn.layer.cornerRadius = 16
//            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return btn
        }()
        
        private lazy var dataSource: [Date] = {
            var years = (12...100).compactMap {
                currentCalendar.date(byAdding: .year, value: -$0, to: todayNow)
            }
            years.insert(todayNow, at: 0)
            return years
        }()
        
        private let todayNow = Date()
        
        private let currentCalendar = Calendar.current
        
        var completion: (() -> Void)? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            Logger.Action.log(.room_enter_set_age_imp, categoryValue: topicId)
        }
        
    }
    
}

extension Social.AgePromptModal {
    
    @objc
    private func onCloseBtn() {
        dismissSelf()
    }
    
    @objc
    private func onGoBtn() {
        Logger.Action.log(.room_enter_set_age_confirm, categoryValue: topicId)
        
        promptView.removeFromSuperview()
        
        view.addSubviews(views: setAgeView)
        setAgeView.layer.cornerRadius = 20
        let height = 371 + Frame.Height.safeAeraBottomHeight
        setAgeView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(height)
            maker.bottom.equalToSuperview().offset(20)
        }
        
        setAgeView.transform = CGAffineTransform(translationX: 0, y: height)
        let transitionAnimator = UIViewPropertyAnimator(duration: AnimationDuration.normal.rawValue, dampingRatio: 1, animations: { [weak self] in
            self?.setAgeView.transform = .identity
        })
        transitionAnimator.startAnimation()
    }
    
    @objc
    private func onSaveBtn() {
        
        guard let date = dataSource.safe(birthdayPicker.selectedRow(inComponent: 0)),
              date != todayNow else {
            dismissSelf()
            return
        }
        
        Logger.Action.log(.room_enter_set_age_save, categoryValue: topicId)
        
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let birthdayStr = df.string(from: date)
        
        let profile = Entity.ProfileProto(birthday: birthdayStr, name: nil, pictureUrl: nil)
        
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        Request.updateProfile(profile)
            .do(onDispose: { [weak self] in
                hudRemoval()
                self?.dismissSelf()
            })
            .subscribe(onSuccess: { (_) in
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
}

extension Social.AgePromptModal {
    
    private func setUpLayout() {
        
        view.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.7)
        view.addSubviews(views: promptView)
        
        promptView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(28)
        }
    }
    
    private func setUpEvents() {
        
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { (_) in
                Defaults[\.setAgePromptShowsTime] = Date().timeIntervalSince1970
            })
            .disposed(by: bag)
        
        birthdayPicker.rx.itemSelected
            .subscribe(onNext: { [weak self] (row, _) in
                if row == 0 {
                    self?.saveBtn.isEnabled = false
                    self?.saveBtn.backgroundColor = UIColor(hex6: 0x2B2B2B)
                } else {
                    self?.saveBtn.isEnabled = true
                    self?.saveBtn.backgroundColor = UIColor(hex6: 0xFFF000)
                }
            })
            .disposed(by: bag)
    }
    
    private func dismissSelf() {
        dismiss(animated: false) { [weak self] in
            self?.completion?()
        }
    }
    
}

extension Social.AgePromptModal {
    
    class func showModalIfNeeded(fromVC: UIViewController, topicId: String, completion: @escaping (() -> Void) ) {
        
        guard FireRemote.shared.value.age_prompt_enable,
            Settings.shared.amongChatUserProfile.value?.birthday?.isEmpty ?? true,
            Defaults[\.setAgePromptShowsTime] == nil else {
            completion()
            return
        }
        
        let prompt = Social.AgePromptModal()
        prompt.topicId = topicId
        prompt.completion = completion
        prompt.modalPresentationStyle = .overCurrentContext
        fromVC.present(prompt, animated: false)
    }
    
}

extension Social.AgePromptModal: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
}

extension Social.AgePromptModal: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 48
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        guard let date = dataSource.safe(row) else {
            return UIView()
        }
        
        guard date != todayNow  else {
            let view: UIView = {
                let v = UIView()
                
                let dash = { () -> UIView in
                    let v = UIView()
                    v.backgroundColor = .white
                    v.layer.cornerRadius = 2
                    return v
                }
                
                let dash1 = dash()
                let dash2 = dash()
                v.addSubviews(views: dash1, dash2)
                let layoutGuide = UILayoutGuide()
                v.addLayoutGuide(layoutGuide)
                layoutGuide.snp.makeConstraints { (maker) in
                    maker.center.equalToSuperview()
                }
                
                dash1.snp.makeConstraints { (maker) in
                    maker.leading.top.bottom.equalTo(layoutGuide)
                    maker.width.equalTo(20)
                    maker.height.equalTo(4)
                }
                
                dash2.snp.makeConstraints { (maker) in
                    maker.trailing.top.bottom.equalTo(layoutGuide)
                    maker.width.equalTo(20)
                    maker.height.equalTo(4)
                    maker.leading.equalTo(dash1.snp.trailing).offset(4)
                }
                
                return v
            }()
            return view
        }
        
        let label: UILabel
        
        if let lb = view as? UILabel {
            label = lb
        } else {
            label = {
                let l = UILabel()
                l.font = R.font.nunitoExtraBold(size: 32)
                l.textColor = .white
                l.textAlignment = .center
                return l
            }()
        }
        
        if let years = currentCalendar.dateComponents([.year], from: date, to: todayNow).year {
            label.text = years < 13 ? "< 13" : years.string
        } else {
            label.text = nil
        }
        
        return label
    }
}
