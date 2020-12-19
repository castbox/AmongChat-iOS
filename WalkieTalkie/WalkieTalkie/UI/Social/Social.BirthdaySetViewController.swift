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
        
        private lazy var mainTitle: UILabel = {
            let label = UILabel()
            label.textColor = UIColor(hex6: 0xFFF000)
            label.font = R.font.nunitoExtraBold(size: 48)
            label.text = "BIrthday"
            label.textAlignment = .center
            return label
        }()
        
        private lazy var subTitle: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.font = R.font.nunitoExtraBold(size: 16)
            label.text = "Find friends of the same age"
            label.textAlignment = .center
            label.numberOfLines = 2
            return label
        }()
        
        private lazy var birthdayPicker: Social.DatePickerView = {
            let p = Social.DatePickerView(frame: CGRect(x: 40, y: 305, width: Frame.Screen.width - 80, height: 290))
            p.backgroundColor = UIColor(hex6: 0x121212)
            return p
        }()
        
        private lazy var confirmBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoBlack(size: 20)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            btn.setTitle("Done", for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 25
            return btn
        }()
        
        var onCompletion: ((String) -> Void)? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor(hex6: 0x121212)
            
            view.addSubviews(views: mainTitle, subTitle, birthdayPicker, confirmBtn)
            
            mainTitle.snp.makeConstraints { (maker) in
                maker.top.equalTo(140)
                maker.centerX.equalToSuperview()
                maker.height.equalTo(65.5)
            }
            
            subTitle.snp.makeConstraints { (maker) in
                maker.top.equalTo(mainTitle.snp.bottom).offset(8)
                maker.left.equalTo(40)
                maker.right.equalTo(-40)
            }
            
            birthdayPicker.snp.makeConstraints { (maker) in
                maker.left.equalTo(35)
                maker.right.equalTo(-35)
                maker.height.equalTo(290)
                maker.top.equalTo(subTitle.snp.bottom).offset(50)
            }
            
            confirmBtn.snp.makeConstraints { (maker) in
                maker.left.equalTo(40)
                maker.right.equalTo(-40)
                maker.height.equalTo(50)
                maker.bottom.equalTo(-58 - Frame.Height.safeAeraBottomHeight)
            }
            
            birthdayPicker.selectBirthday("2005/01/01")
        }
        
        @objc
        private func onConfirmBtn() {
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd"
            let birthdayStr = df.string(from: birthdayPicker.date)
            
            let profile = Entity.ProfileProto(birthday: birthdayStr, name: nil, pictureUrl: nil)
            
            if let dict = profile.dictionary {
                let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
                let _ = Request.updateProfile(dict)
                    .do(onDispose: {
                        hudRemoval()
                    })
                    .subscribe(onSuccess: { [weak self] (profile) in
                        guard let p = profile else { return }
                        Settings.shared.amongChatUserProfile.value = p
                        self?.onCompletion?(birthdayStr)
                    }, onError: { (error) in
                        
                    })
            }
        }
    }
}

extension Social.BirthdaySetViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return Frame.Screen.height
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 0
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
    
}
