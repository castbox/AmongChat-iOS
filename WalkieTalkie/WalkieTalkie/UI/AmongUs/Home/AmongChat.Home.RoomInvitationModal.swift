//
//  AmongChat.Home.RoomInvitationModal.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension AmongChat.Home {
    
    class RoomInvitationModal: WalkieTalkie.ViewController {
        
        private lazy var countDownLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 12)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var circleView: UIView = {
            let v = UIView()
            return v
        }()

        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 40
            iv.layer.masksToBounds = true
            iv.setImage(with: URL(string: user.pictureUrl))
            return iv
        }()
                
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.text = user.name
            return lb
        }()
        
        private lazy var msgLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.numberOfLines = 0
            lb.text = R.string.localizable.amongChatChannelInvitationMsg(room.topicName.uppercased())
            return lb
        }()
        
        private lazy var ignoreBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.setTitle(R.string.localizable.amongChatIgnore(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.borderWidth = 2
            btn.layer.cornerRadius = 18
            return btn
        }()

        private lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.socialJoinAction().uppercased(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 18
            return btn
        }()
        
        private lazy var container: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.layer.cornerRadius = 12
            v.layer.masksToBounds = true
            return v
        }()
        
        private let user: Entity.UserProfile
        private let room: Entity.FriendUpdatingInfo.Room
        
        init(with inviter: Entity.UserProfile, room: Entity.FriendUpdatingInfo.Room) {
            self.user = inviter
            self.room = room
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
        
        private func setupLayout() {
            
            view.backgroundColor = UIColor.black.alpha(0.5)
            
            view.addSubview(container)
            container.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview().inset(28)
                maker.centerY.equalToSuperview()
            }
            
            let actionBtnStack = UIStackView(arrangedSubviews: [ignoreBtn, joinBtn],
                                             axis: .horizontal,
                                             spacing: 20,
                                             alignment: .center,
                                             distribution: .fillEqually)
            
            container.addSubviews(views: circleView, countDownLabel, avatarIV, nameLabel, msgLabel, actionBtnStack)
            
            circleView.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview().inset(20)
                maker.width.height.equalTo(27)
            }
            
            countDownLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(circleView)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalToSuperview().offset(40)
                maker.width.height.equalTo(80)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(8)
                maker.left.greaterThanOrEqualToSuperview().inset(20)
                maker.centerX.equalToSuperview()
            }
            
            msgLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(4)
                maker.left.right.equalToSuperview().inset(20)
            }
            
            actionBtnStack.snp.makeConstraints { (maker) in
                maker.top.equalTo(msgLabel.snp.bottom).offset(20)
                maker.height.equalTo(36)
                maker.bottom.equalToSuperview().inset(40)
                maker.left.right.equalToSuperview().inset(20)
            }
            
        }
        
        private func setupEvent() {
            
            let tap = UITapGestureRecognizer()
            view.addGestureRecognizer(tap)
            tap.rx.event.subscribe(onNext: { [weak self] (_) in
                self?.dismiss(animated: false)
            })
            .disposed(by: bag)
            
            rx.viewDidAppear
                .take(1)
                .subscribe(onNext: { [weak self] (_) in
                    self?.countDownLabel.text = "15"
                    let countDown = 15 // 15 seconds
                    let _ = Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
                            .take(countDown+1)
                            .subscribe(onNext: { timePassed in
                                let count = countDown - timePassed
                                self?.countDownLabel.text = "\(count)"
                            }, onCompleted: {
                                self?.dismiss(animated: false)
                            })
                })
                .disposed(by: bag)

        }
        
        func bindEvent(join: @escaping () -> Void, ignore: @escaping () -> Void) {
            
            joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    join()
                })
                .disposed(by: bag)
            
            ignoreBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    ignore()
                })
                .disposed(by: bag)
            
        }
        
    }
    
}
