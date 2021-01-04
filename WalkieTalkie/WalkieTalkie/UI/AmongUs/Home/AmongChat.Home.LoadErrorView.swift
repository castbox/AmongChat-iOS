//
//  AmongChat.Home.LoadErrorView.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/19.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class LoadErrorView: UIView {
        
        private lazy var icon: UIImageView = {
            let i = UIImageView(image: R.image.ac_home_load_error())
            i.contentMode = .scaleAspectFit
            return i
        }()
        
        private lazy var title: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.text = R.string.localizable.amongChatHomeLoadErrorTitle()
            lb.textColor = .white
            return lb
        }()
        
        private lazy var msg: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoSemiBold(size: 12)
            lb.text = R.string.localizable.amongChatHomeLoadErrorMsg()
            lb.textColor = UIColor(hex6: 0xABABAB)
            return lb
        }()
        
        private lazy var tryAgainBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.amongChatTryAgain(), for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            btn.layer.cornerRadius = 18
            btn.layer.masksToBounds = true
            btn.addTarget(self, action: #selector(onRetryBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        typealias ActionHandler = (() -> Void)
        
        private var handler: ActionHandler?
                
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            
            self.backgroundColor = UIColor.theme(.backgroundBlack)
            
            let contentLayoutGuide = UILayoutGuide()
            addLayoutGuide(contentLayoutGuide)
            
            contentLayoutGuide.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.centerY.equalToSuperview()
            }
            
            addSubviews(views: icon, title, msg, tryAgainBtn)
            
            icon.snp.makeConstraints { (maker) in
                maker.top.equalTo(contentLayoutGuide)
                maker.left.right.equalToSuperview()
                maker.height.equalTo(icon.snp.width).multipliedBy(120.0/375.0)
            }
            
            title.snp.makeConstraints { (maker) in
                maker.top.equalTo(icon.snp.bottom).offset(4)
                maker.centerX.equalToSuperview()
                maker.left.greaterThanOrEqualToSuperview().offset(40)
            }
            
            msg.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.width.greaterThanOrEqualTo(215)
                maker.top.equalTo(title.snp.bottom).offset(4)
            }
            
            tryAgainBtn.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(msg.snp.bottom).offset(24)
                maker.height.equalTo(36)
                maker.bottom.equalTo(contentLayoutGuide)
            }
            
        }
        
        @objc
        private func onRetryBtn() {
            handler?()
        }
                
        @discardableResult
        func showUp(actionHandler: @escaping ActionHandler) -> (() -> Void) {
            handler = actionHandler
            return {
            }
            
        }
        
    }
    
}
