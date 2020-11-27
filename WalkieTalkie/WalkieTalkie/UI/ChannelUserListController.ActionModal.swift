//
//  ChannelUserListController.ActionModal.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/10.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension ChannelUserListController {
    
    class ActionModal: WalkieTalkie.ViewController, Modalable {
        
        private lazy var iconIV: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 20)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 1.0)
            return lb
        }()
        
        private lazy var textLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.numberOfLines = 0
            lb.font = R.font.nunitoSemiBold(size: 14)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 0.54)
            return lb
        }()
        
        private lazy var muteBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onMuteBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.channelUserListMuteAction(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        private lazy var blockBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onBlockBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.alertBlock(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        private let viewModel: ChannelUserViewModel
        
        private let actionType: ActionType
        
        var actionHandler: (() -> Void)? = nil
        
        enum ActionType {
            case mute
            case block
        }
        
        init(with userViewModel: ChannelUserViewModel, actionType: ActionType) {
            viewModel = userViewModel
            self.actionType = actionType
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
        private func setupLayout() {
            view.backgroundColor = .white
            view.addSubviews(views: iconIV, titleLabel, textLabel)
            
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
            
            switch actionType {
            case .mute:
                iconIV.image = R.image.channel_user_list_mute()
                titleLabel.text = R.string.localizable.channelUserListMuteActionTitle()
                titleLabel.appendKern()
                textLabel.text = R.string.localizable.channelUserListMuteActionMsg()
                textLabel.appendKern()
                
                view.addSubview(muteBtn)
                muteBtn.snp.makeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.top.equalTo(titleLabel.snp.bottom).offset(88)
                    maker.width.equalTo(225)
                    maker.height.equalTo(48)
                }
                
                let proLabel: UILabel = {
                    let lb = WalkieLabel()
                    lb.font = R.font.nunitoBoldItalic(size: 10)
                    lb.textColor = UIColor(hex6: 0xD0021B, alpha: 1.0)
                    lb.text = R.string.localizable.channelUserListProBadge()
                    lb.appendKern()
                    return lb
                }()
                
                view.insertSubview(proLabel, aboveSubview: muteBtn)
                proLabel.snp.makeConstraints { (maker) in
                    maker.centerY.equalTo(muteBtn)
                    maker.right.equalTo(muteBtn).offset(-15)
                }
                
            case .block:
                iconIV.image = R.image.channel_user_list_block()
                titleLabel.text = R.string.localizable.channelUserListBlockActionTitle()
                titleLabel.appendKern()
                textLabel.text = R.string.localizable.channelUserListBlockActionMsg()
                textLabel.appendKern()
                
                view.addSubview(blockBtn)
                blockBtn.snp.makeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.top.equalTo(titleLabel.snp.bottom).offset(88)
                    maker.width.equalTo(225)
                    maker.height.equalTo(48)
                }
            }
        }
        
        @objc
        private func onMuteBtn() {
            defer {
                dismissModal(animated: true)
            }
            
            // mute_halfpage_clk log
            GuruAnalytics.log(event: "mute_halfpage_clk", category: nil, name: nil, value: nil, content: nil)
            //
            
            guard Settings.shared.isProValue.value else {
                
                let sb = UIStoryboard(name: "Main", bundle: nil)
                
                let premiumVC = sb.instantiateViewController(withIdentifier: "PremiumViewController") as! PremiumViewController
                
                premiumVC.source = .mute
                premiumVC.style = .likeGuide
                premiumVC.dismissHandler = {
                    premiumVC.dismiss(animated: true, completion: nil)
                }
                premiumVC.modalPresentationStyle = .fullScreen
                UIApplication.topViewController()?.present(premiumVC, animated: true, completion: nil)
                
                return
            }
            
            actionHandler?()
        }
        
        @objc
        private func onBlockBtn() {
            defer {
                dismissModal(animated: true)
            }
            // block_halfpage_clk log
            GuruAnalytics.log(event: "block_halfpage_clk", category: nil, name: nil, value: nil, content: nil)
            //
            actionHandler?()
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
