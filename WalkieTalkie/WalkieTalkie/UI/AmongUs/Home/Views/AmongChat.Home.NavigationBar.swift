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
        
        enum Style {
            case `default`
            case notice
        }
        
        private lazy var profileBtn: UIButton = {
            let btn = UIButton(type: .custom)
            
            Settings.shared.profilePage.replay()
                .subscribe(onNext: { (p) in
                    if let avatar = p?.profile?.pictureUrl?.url,
                       p?.profile?.isAnonymous == false {
                        btn.setImage(with: avatar, for: .normal)
                        btn.imageView?.layer.cornerRadius = 16
                        btn.imageView?.clipsToBounds = true
                    } else {
                        btn.setImage(R.image.ac_home_profile(), for: .normal)
                        btn.imageView?.layer.cornerRadius = 0
                        btn.imageView?.clipsToBounds = false
                    }
                })
                .disposed(by: bag)
            
            Settings.shared.amongChatAvatarListShown.replay()
                .subscribe(onNext: { (ts) in
                    if let _ = ts {
                        btn.badgeOff()
                    } else {
                        btn.badgeOn(hAlignment: .tailByTail(-5), topInset: -1, diameter: 13)
                    }
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
        
        private lazy var searchTextfield: Search.TextField = {
            let textfield = Search.TextField(fontSize: Frame.Height.deviceDiagonalIsMinThan4_7 ? 16 : 18)
            textfield.delegate = self
            textfield.textAlignment = .center
            textfield.setContentHuggingPriority(.required, for: .horizontal)
            return textfield
        }()
        
        private lazy var noticeBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_notice(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { () in
                    Routes.handle("/allNotice")
                    Logger.Action.log(.dm_notice_clk)
                })
                .disposed(by: bag)
            
            Settings.shared.hasUnreadNoticeRelay
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { (hasUnread) in
                    
                    if hasUnread {
                        btn.badgeOn(hAlignment: .tailByTail(-5), topInset: -1, diameter: 13)
                    } else {
                        btn.badgeOff()
                    }
                    
                })
                .disposed(by: bag)

            return btn
        }()
        
        private let bag = DisposeBag()
        
        private let style: Style
        
        init(_ style: Style = .default) {
            self.style = style
            super.init(frame: .zero)
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func configureSubview() {
            
            let layout = UILayoutGuide()
            addLayoutGuide(layout)
            layout.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.height.equalTo(49)
            }
            
            let hEdgeInset = Frame.horizontalBleedWidth
            switch style {
            case .default:
                addSubviews(views: profileBtn, searchTextfield, createRoomBtn)
                profileBtn.snp.makeConstraints { (maker) in
                    maker.width.height.equalTo(32)
                    maker.leading.equalToSuperview().inset(hEdgeInset)
                    maker.centerY.equalToSuperview()
                }
                
                createRoomBtn.snp.makeConstraints { (maker) in
                    maker.trailing.equalToSuperview().inset(hEdgeInset)
                    maker.width.height.equalTo(32)
                    maker.centerY.equalToSuperview()
                }
                
                searchTextfield.snp.makeConstraints { (maker) in
                    maker.leading.equalTo(profileBtn.snp.trailing).offset(20)
                    maker.trailing.equalTo(createRoomBtn.snp.leading).offset(-20)
                    maker.centerY.equalToSuperview()
                    maker.height.equalTo(36)
                }
                
            case .notice:
                addSubviews(views: searchTextfield, noticeBtn)
                
                searchTextfield.snp.makeConstraints { (maker) in
                    maker.leading.equalToSuperview().offset(hEdgeInset)
                    maker.trailing.equalTo(noticeBtn.snp.leading).offset(-20)
                    maker.centerY.equalToSuperview()
                    maker.height.equalTo(36)
                }
                                
                noticeBtn.snp.makeConstraints { (maker) in
                    maker.width.height.equalTo(32)
                    maker.trailing.equalToSuperview().inset(hEdgeInset)
                    maker.centerY.equalToSuperview()
                }
                
            }
        }
        
        @objc
        private func onProfileBtn() {
            Routes.handle("/profile")
        }
        
        @objc
        private func onCreateRoomBtn() {
            guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: .createChannel)) else {
                return
            }
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
