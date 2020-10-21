//
//  RoomViewController.SpeakingModal.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/10/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension RoomViewController {
    
    class SpeakingModal: WalkieTalkie.ViewController, Modalable {
        
        private lazy var iconIV: UIImageView = {
            let iv = UIImageView(image: R.image.icon_setting_diamonds())
            return iv
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 20)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 1.0)
            lb.text = R.string.localizable.channelSpeakingLimitModalTitle()
            return lb
        }()
        
        private lazy var textLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.numberOfLines = 0
            lb.font = R.font.nunitoSemiBold(size: 14)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 0.54)
            lb.text = R.string.localizable.channelSpeakingLimitModalMsg()
            return lb
        }()
        
        private lazy var upgradeBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onUpgradeBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.channelSpeakingLimitModalUpgrade(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            return btn
        }()
                
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            let _ = rx.viewDidAppear
                .take(1)
                .subscribe(onNext: {
                    GuruAnalytics.log(event: "iap_tip_imp", category: nil, name: nil, value: nil, content: nil)
                })
        }
        
        private func setupLayout() {
            view.backgroundColor = .white
            view.addSubviews(views: iconIV, titleLabel, textLabel, upgradeBtn)
            
            iconIV.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(30)
                maker.centerX.equalToSuperview()
                maker.width.height.equalTo(60)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(iconIV.snp.bottom).offset(15)
                maker.height.equalTo(27)
            }
            
            textLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(titleLabel.snp.bottom).offset(10)
                maker.left.greaterThanOrEqualToSuperview().offset(25)
            }
                                
            upgradeBtn.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(titleLabel.snp.bottom).offset(88)
                maker.width.equalTo(225)
                maker.height.equalTo(48)
            }
        }
        
        
        @objc
        private func onUpgradeBtn() {
            defer {
                dismissModal(animated: true)
            }
            
            GuruAnalytics.log(event: "iap_tip_clk", category: nil, name: nil, value: nil, content: nil)
            
            let sb = UIStoryboard(name: "Main", bundle: nil)
            
            let premiumVC = sb.instantiateViewController(withIdentifier: "PremiumViewController") as! PremiumViewController
            
            premiumVC.source = .iap_tip
            premiumVC.dismissHandler = {
                premiumVC.dismiss(animated: true, completion: nil)
            }
            premiumVC.modalPresentationStyle = .fullScreen
            navigationController?.present(premiumVC, animated: true, completion: nil)

        }
        
        // MARK: - Modalable
        
        func style() -> Modal.Style {
            return .customHeight
        }
        
        func height() -> CGFloat {
            return 308 + Frame.Height.safeAeraBottomHeight
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

}
