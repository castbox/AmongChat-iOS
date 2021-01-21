//
//  BirthdaySetViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    
    class BirthdaySetViewController: ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_back(), for: .normal)
            return btn
        }()
        
        private lazy var birthdayIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_set_birthday_birthday())
            return i
        }()
        
        private lazy var mainTitle: UILabel = {
            let label = UILabel()
            label.textColor = UIColor(hex6: 0xFFF000)
            label.font = R.font.nunitoExtraBold(size: 48)
            label.text = R.string.localizable.amongChatSetBirthDayTitle()
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        private lazy var subTitle: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = R.font.nunitoExtraBold(size: 16)
            label.text = R.string.localizable.profileBirthdaySubtitle()
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        private lazy var birthdayPicker: UIPickerView = {
            let p = UIPickerView(frame: CGRect(x: 40, y: 305, width: Frame.Screen.width - 70, height: 290))
            p.backgroundColor = UIColor(hex6: 0x121212)
            p.dataSource = self
            p.delegate = self
            return p
        }()
        
        private lazy var confirmBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoBlack(size: 20)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            btn.setTitle(R.string.localizable.profileDone(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.backgroundColor = UIColor(hex6: 0x2B2B2B)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 25
            btn.isEnabled = false
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
        
        var onCompletion: ((String) -> Void)? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.addSubviews(views: backBtn, birthdayIcon, mainTitle, subTitle, birthdayPicker, confirmBtn)
            
            let navLayoutGuide = UILayoutGuide()
            view.addLayoutGuide(navLayoutGuide)
            navLayoutGuide.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
                maker.height.equalTo(49)
            }
            
            backBtn.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.centerY.equalTo(navLayoutGuide)
                maker.width.height.equalTo(24)
            }
            
            birthdayIcon.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(navLayoutGuide.snp.bottom).offset(24)
            }
            
            mainTitle.snp.makeConstraints { (maker) in
                maker.top.equalTo(birthdayIcon.snp.bottom).offset(8)
                maker.leading.trailing.equalToSuperview().inset(30)
            }
            
            subTitle.snp.makeConstraints { (maker) in
                maker.top.equalTo(mainTitle.snp.bottom).offset(7)
                maker.leading.trailing.equalToSuperview().inset(40)
            }
            var gap = 50
            if Frame.Height.deviceDiagonalIsMinThan5_5 {
                gap = 40
            }
            birthdayPicker.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(30)
                maker.height.equalTo(290)
                maker.top.equalTo(subTitle.snp.bottom).offset(gap)
            }
            
            confirmBtn.snp.makeConstraints { (maker) in
                maker.left.equalTo(40)
                maker.right.equalTo(-40)
                maker.height.equalTo(50)
                maker.bottom.equalTo(-58 - Frame.Height.safeAeraBottomHeight)
            }
            
            rx.viewDidAppear.take(1)
                .subscribe(onNext: { (_) in
                    Logger.Action.log(.login_birthday_imp)
                })
                .disposed(by: bag)
            
            birthdayPicker.rx.itemSelected.subscribe(onNext: { [weak self] (row, _) in
                
                if row == 0 {
                    self?.confirmBtn.isEnabled = false
                    self?.confirmBtn.backgroundColor = UIColor(hex6: 0x2B2B2B)
                } else {
                    self?.confirmBtn.isEnabled = true
                    self?.confirmBtn.backgroundColor = UIColor(hex6: 0xFFF000)
                }
            })
            .disposed(by: bag)
        }
        
        @objc
        func onBackBtn() {
            Logger.Action.log(.login_birthday_skip)
            onCompletion?("")
        }
        
        @objc
        private func onConfirmBtn() {
            Logger.Action.log(.login_birthday_done)
            
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd"
            let birthdayStr: String
            if let date = dataSource.safe(birthdayPicker.selectedRow(inComponent: 0)) {
                birthdayStr = df.string(from: date)
            } else {
                birthdayStr = "20050101"
            }
            
            let profile = Entity.ProfileProto(birthday: birthdayStr, name: nil, pictureUrl: nil)
            
            let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
            let _ = Request.updateProfile(profile)
                .do(onDispose: {
                    hudRemoval()
                })
                .subscribe(onSuccess: { [weak self] (profile) in
                    defer {
                        Logger.Action.log(.login_birthday_success, category: nil, birthdayStr)
                        self?.onCompletion?(birthdayStr)
                    }
                    guard let p = profile else { return }
                    Settings.shared.amongChatUserProfile.value = p
                }, onError: { [weak self] (error) in
                    self?.view.raft.autoShow(.text("\(error.localizedDescription)"))
                })
        }
    }
}

extension Social.BirthdaySetViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
}

extension Social.BirthdaySetViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 48
    }
        
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        guard let date = dataSource.safe(row),
              date != todayNow else {
            return UIView()
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
