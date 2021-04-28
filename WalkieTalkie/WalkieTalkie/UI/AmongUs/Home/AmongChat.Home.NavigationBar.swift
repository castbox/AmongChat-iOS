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
            Settings.shared.profilePage.replay()
                .subscribe(onNext: { (p) in
                    guard let avatar = p?.profile?.pictureUrl?.url else { return }
                    btn.setImage(with: avatar, for: .normal)
                    btn.imageView?.layer.cornerRadius = 16
                    btn.imageView?.clipsToBounds = true
                })
                .disposed(by: bag)

            
            btn.addTarget(self, action: #selector(onProfileBtn), for: .primaryActionTriggered)
            return btn
        }()
                
        private lazy var createRoomBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_create(), for: .normal)
            btn.addTarget(self, action: #selector(onCreateRoomBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var noticeBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_notice(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { () in
                    Routes.handle("/allNotice")
                    Logger.Action.log(.home_search_clk)
                })
                .disposed(by: bag)
            return btn
        }()

        private lazy var searchBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_search(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { () in
                    Routes.handle("/search")
                    Logger.Action.log(.home_search_clk)
                })
                .disposed(by: bag)
            return btn
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
                        self?.profileBtn.badgeOff()
                    } else {
                        self?.profileBtn.badgeOn(hAlignment: .tailByTail(-2), topInset: -1, diameter: 13)
                    }
                })
                .disposed(by: bag)
            
            Settings.shared.hasUnreadNoticeRelay
                .subscribe(onNext: { [weak self] (hasUnread) in
                    
                    if hasUnread {
                        self?.noticeBtn.badgeOn(hAlignment: .tailByTail(-5), topInset: -1, diameter: 13)
                    } else {
                        self?.redDotOff()
                    }
                    
                })
                .disposed(by: bag)
        }
        
        private func configureSubview() {
            addSubviews(views: profileBtn, searchBtn, noticeBtn, createRoomBtn)
            
            profileBtn.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview().inset(8.5)
                maker.width.height.equalTo(32)
                maker.leading.equalToSuperview().inset(20)
            }
            
            createRoomBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(20)
                maker.centerY.equalToSuperview()
            }
            
            noticeBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalTo(createRoomBtn.snp.leading).offset(-24)
                maker.centerY.equalToSuperview()
            }
            
            searchBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalTo(noticeBtn.snp.leading).offset(-24)
                maker.centerY.equalToSuperview()
            }
        }
        
        @objc
        private func onProfileBtn() {
            Routes.handle("/profile")
        }
        
        @objc
        private func onCreateRoomBtn() {
            guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: R.string.localizable.amongChatLoginAuthSourceChannel())) else {
                return
            }
            Routes.handle("/createRoom")
        }
        
    }
}
