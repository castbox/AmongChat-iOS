//
//  BirthdaySelectViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 19/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SnapKit

extension Social {
    class BirthdaySelectViewController: ViewController {
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 27)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var constellationLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 27)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var birthdayPicker: Social.DatePickerView = {
            let p = Social.DatePickerView(frame: CGRect(x: 0, y: 58, width: Frame.Screen.width, height: 260))
            p.backgroundColor = UIColor(hex6: 0x222222)
            return p
        }()
        
        private lazy var confirmBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            btn.setTitle(R.string.localizable.profileEditSaveBtn(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return btn
        }()
                
        var onCompletion: ((String, Constellation?) -> Void)? = nil
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            //update
            updateAgeTitle()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = UIColor(hex6: 0x222222)
            view.addSubviews(views: titleLabel, constellationLabel, birthdayPicker, confirmBtn)
            
            confirmBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(20)
                maker.top.equalToSuperview().offset(20)
                maker.height.equalTo(32)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(confirmBtn.snp.bottom).offset(20)
                maker.centerX.equalToSuperview()
                maker.leading.greaterThanOrEqualToSuperview().inset(20)
            }
            
            constellationLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom).offset(8)
                maker.centerX.equalToSuperview()
                maker.leading.greaterThanOrEqualToSuperview().inset(20)
            }
            
            birthdayPicker.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(constellationLabel.snp.bottom).offset(27.5)
                maker.height.equalTo(235)
            }
            
            birthdayPicker.onDateUpdateHandler = { [weak self] in
                self?.updateAgeTitle()
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
            let birthdayStr: String
            if let date = birthdayPicker.date {
                birthdayStr = df.string(from: date)
            } else {
                birthdayStr = "20050101"
            }
            let constellation = df.date(from: birthdayStr)?.constellation()
            dismissModal(animated: true) { [weak self] in
                self?.onCompletion?(birthdayStr, constellation)
            }
        }
        
        func updateAgeTitle() {
            let now = Date()
            let birthday = birthdayPicker.date ?? Date()
            let calendar = Calendar(identifier: .gregorian)
            let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
            let age = ageComponents.year!
            //
            titleLabel.text = R.string.localizable.changeOldTitle(age.string)
            constellationLabel.text = "⭐️ " + (birthday.constellation()?.title ?? "")
        }
    }
}

extension Social.BirthdaySelectViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 415 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func containerCornerRadius() -> CGFloat {
        return 20
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
