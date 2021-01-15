//
//  AmongChat.Home.NavigationBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 13/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension AmongChat.Home {
    
    class NavigationBar: UIView {
        private lazy var profileBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_profile(), for: .normal)
            btn.addTarget(self, action: #selector(onProfileBtn), for: .primaryActionTriggered)
            return btn
        }()
                
        private lazy var createRoomBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_create(), for: .normal)
            btn.addTarget(self, action: #selector(onCreateRoomBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var searchTextfield: Search.TextField = {
            let textfield = Search.TextField(fontSize: Frame.Height.deviceDiagonalIsMinThan5_5 ? (Frame.Height.deviceDiagonalIsMinThan4_7 ? 16 : 18) : 20)
            textfield.delegate = self
            textfield.textAlignment = .center
            textfield.setContentHuggingPriority(.required, for: .horizontal)
            return textfield
        }()
        
        private let bag = DisposeBag()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            Settings.shared.amongChatAvatarListShown.replay()
                .subscribe(onNext: { [weak self] (ts) in
                    if let _ = ts {
                        self?.profileBtn.redDotOff()
                    } else {
                        self?.profileBtn.redDotOn(rightOffset: 0, topOffset: 0)
                    }
                })
                .disposed(by: bag)
        }
        
        private func configureSubview() {
            addSubviews(views: profileBtn, searchTextfield, createRoomBtn)
            
            profileBtn.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(42)
                maker.leading.equalToSuperview().inset(20)
                maker.centerY.equalTo(searchTextfield)
            }
            
            createRoomBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(20)
                maker.width.height.equalTo(42)
                maker.centerY.equalTo(searchTextfield)
            }
            
            searchTextfield.snp.makeConstraints { (maker) in
                maker.leading.equalTo(profileBtn.snp.trailing).offset(10)
                maker.trailing.equalTo(createRoomBtn.snp.leading).offset(-10)
                maker.bottom.equalTo(-6.5)
                maker.height.equalTo(36)
            }
        }
        
        @objc
        private func onProfileBtn() {
            Routes.handle("/profile")
        }
        
        @objc
        private func onCreateRoomBtn() {
            Routes.handle("/createRoom")
        }
        
    }
}

extension AmongChat.Home.NavigationBar: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        Routes.handle("/search")
        Logger.Action.log(.home_search_clk)
        return false
    }
}
