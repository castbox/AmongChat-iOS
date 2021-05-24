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
        
        private lazy var circleView: CircularProgressView = {
            let v = CircularProgressView()
            
            v.backgroundColor = .clear
            
            v.circleLineWidth = 2.5
            v.circleLineColor = UIColor.white.alpha(0.19)
            v.circleBackgroundColor = .clear
            
            v.progressLineWidth = 2.5
            v.progressLineColor = .white
            v.progressBackgroundColor = .clear
            
            return v
        }()

        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 40
            iv.layer.masksToBounds = true
            return iv
        }()
                
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var msgLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.numberOfLines = 0
            return lb
        }()
        
        private lazy var ignoreBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.setTitle(R.string.localizable.amongChatIgnore().uppercased(), for: .normal)
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
        
        private var countdownDisposable: Disposable? = nil
        private var joinBtnDisposable: Disposable? = nil
        private var ignoreBtnDisposable: Disposable? = nil
        
        private var room: Peer.FriendUpdatingInfo.Room? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
        
        private func setupLayout() {
            
            view.backgroundColor = UIColor.black.alpha(0.5)
            
            var hInset: CGFloat = 28
            
            adaptToIPad {
                hInset = 190
            }
            
            view.addSubview(container)
            container.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview().inset(hInset)
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
                maker.left.equalTo(20)
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
            
            let containerTap = UITapGestureRecognizer()
            container.addGestureRecognizer(containerTap)
            containerTap.rx.event.subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        }
        
        private func startCountDown() {
            countDownLabel.text = "15"
            let countDown = 15 // 15 seconds
            countdownDisposable?.dispose()
            countdownDisposable = Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
                .take(countDown + 1)
                .subscribe(onNext: { [weak self] timePassed in
                    let count = countDown - timePassed
                    self?.countDownLabel.text = "\(count)"
                }, onCompleted: { [weak self] in
                    self?.dismiss(animated: false)
                    Logger.Action.log(.invite_dialog_auto_dimiss, categoryValue: self?.room?.topicId)
                })
            circleView.updateProgress(fromValue: 1, toValue: 0, animationDuration: 15)
        }
        
        func updateContent(user: Entity.UserProfile, room: Peer.FriendUpdatingInfo.Room) {
            self.room = room
            avatarIV.setImage(with: URL(string: user.pictureUrl), placeholder: R.image.ac_profile_avatar())
            nameLabel.attributedText = user.nameWithVerified(fontSize: 20)
            if room.isGroup {
                if room.uid == user.uid {
                    msgLabel.text = R.string.localizable.amongChatGroupAdminInvitationMsg(room.name)
                } else {
                    msgLabel.text = R.string.localizable.amongChatGroupInvitationMsg(room.name)
                }
                
            } else {
                msgLabel.text = R.string.localizable.amongChatChannelInvitationMsg(room.topicName.uppercased())
            }
            startCountDown()
            Logger.Action.log(.invite_dialog_imp, categoryValue: room.topicId)
        }
        
        func bindEvent(join: @escaping () -> Void, ignore: @escaping () -> Void) {
            
            joinBtnDisposable?.dispose()
            joinBtnDisposable = joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    join()
                })
            
            ignoreBtnDisposable?.dispose()
            ignoreBtnDisposable = ignoreBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    ignore()
                })
            
        }
        
    }
    
}

extension AmongChat.Home.RoomInvitationModal {
    
    class CircularProgressView: UIView {
        // First create two layer properties
        private lazy var circleLayer: CAShapeLayer = {
            let l = CAShapeLayer()
            l.shouldRasterize = true
            l.rasterizationScale = 2 * UIScreen.main.scale
            return l
        }()
        
        private lazy var progressLayer: CAShapeLayer = {
            let l = CAShapeLayer()
            l.shouldRasterize = true
            l.rasterizationScale = 2 * UIScreen.main.scale
            return l
        }()
        
        var progressLineColor: UIColor? = nil
        var progressBackgroundColor: UIColor? = nil
        var progressLineWidth: CGFloat = 0.0

        var circleLineColor: UIColor? = nil
        var circleBackgroundColor: UIColor? = nil
        var circleLineWidth: CGFloat = 0.0
        
        var clockwise = false {
            didSet {
                createCircularPath()
            }
        }
        
        init() {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            createCircularPath()
        }
        
        private func setupLayout() {
            layer.addSublayer(circleLayer)
            layer.addSublayer(progressLayer)
        }
        
        private func createCircularPath() {
            
            var startAngle: CGFloat
            var endAngle: CGFloat
            
            if clockwise {
                startAngle = -.pi / 2
                endAngle = 3 * .pi / 2
            } else {
                startAngle = 3 * .pi / 2
                endAngle = -.pi / 2
            }
            
            let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2.0, y: frame.height / 2.0), radius: min(frame.width / 2, frame.height / 2), startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
            circleLayer.path = circularPath.cgPath
            circleLayer.fillColor = circleBackgroundColor?.cgColor
            circleLayer.lineCap = .round
            circleLayer.lineWidth = circleLineWidth
            circleLayer.strokeColor = circleLineColor?.cgColor
            progressLayer.path = circularPath.cgPath
            progressLayer.fillColor = progressBackgroundColor?.cgColor
            progressLayer.lineCap = .round
            progressLayer.lineWidth = progressLineWidth
            progressLayer.strokeEnd = 1.0
            progressLayer.strokeColor = progressLineColor?.cgColor
        }
        
        func updateProgress(fromValue: CGFloat, toValue: CGFloat, animationDuration: TimeInterval) {
            let circularProgressAnimation = CABasicAnimation(keyPath: "strokeEnd")
            circularProgressAnimation.duration = animationDuration
            circularProgressAnimation.fromValue = max(min(1, fromValue), 0)
            circularProgressAnimation.toValue = max(min(1, toValue), 0)
            circularProgressAnimation.fillMode = .forwards
            circularProgressAnimation.isRemovedOnCompletion = false
            progressLayer.add(circularProgressAnimation, forKey: "progressAnim")
        }
        
    }
}
