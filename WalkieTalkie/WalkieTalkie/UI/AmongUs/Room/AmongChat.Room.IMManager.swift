//
//  Among.Chat.Room.IMManager.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/7.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AgoraRtmKit
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[IMManager]-\(message)")
}

extension AmongChat.Room {
    
    class IMManager: NSObject {
        static let shared = IMManager()
        
        private var rtmKit: AgoraRtmKit?
        private let onlineRelay = BehaviorRelay<LoginStatus>(value: .offline)
        private var rtmChannel: AgoraRtmChannel?
        private let joinedSubject = BehaviorRelay<Bool>(value: false)
        private let newChannelMessageSubject = PublishSubject<(AgoraRtmMessage, AgoraRtmMember)>()
        private let newPeerMessageSubject = PublishSubject<(AgoraRtmMessage, String)>()
        
        private var loginDisposable: Disposable?
        private let bag = DisposeBag()
        //max login retry twice
        private var retryCount = 2
        
        var newChannelMessageObservable: Observable<(AgoraRtmMessage, AgoraRtmMember)> {
            return newChannelMessageSubject.asObservable()
        }
        
        var newPeerMessageObservable: Observable<(AgoraRtmMessage, String)> {
            return newPeerMessageSubject.asObservable()
        }
        
        var joinedChannelSignal: Observable<Bool> {
            return joinedSubject.asObservable()
        }
        
        var imIsReady: Bool {
            return joinedSubject.value
        }
        
        override private init() {
            super.init()
            rtmKit = AgoraRtmKit(appId: KeyCenter.AppId, delegate: self)
            bindEvents()
        }
        
        //hdD9gjNe //hdDYMjNf
        private func bindEvents() {
            Settings.shared.loginResult.replay()
                .subscribe(onNext: { [weak self] (result) in
                    self?.retryCount = 2
                    if let _ = result {
                        self?.loginSDK()
                    } else {
                        self?.logoutSDK()
                    }
                    
                })
                .disposed(by: bag)
        }
        
        private func loginSDK() {
            loginDisposable?.dispose()
            loginDisposable = onlineRelay
                .do(onNext: { [weak self] (status) in
                    guard status == .online else {
                        return
                    }
                    self?.logoutSDK()
                })
                .filter { $0 == .offline }
                .take(1)
                .flatMap({ (_) -> Single<Entity.RTMToken?> in
                    cdPrint("requet loginSDK-token")
                    return Request.requestRtmToken()
                })
                .subscribe(onNext: { [weak self] token in
                    guard let `self` = self, let token = token, let uid = Settings.loginUserId?.string else { return }
                    cdPrint("requet loginSDK")
                    self.rtmKit?.login(byToken: token.rcToken, user: uid, completion: { [weak self] (code) in
                        guard let `self` = self else { return }
                        cdPrint("requet loginSDK code: \(code.rawValue)")
                        if code == .ok {
                            self.onlineRelay.accept(.online)
                        } else {
                            self.onlineRelay.accept(.offline)
                            if self.retryCount > 0 {
                                //clear token
                                Settings.shared.cachedRtmToken = nil
                                self.retryCount -= 1
                                self.loginSDK()
                            }
                        }
                    })
                }, onError: { error in
                    cdPrint("error: \(error)")
                })
            loginDisposable?.disposed(by: bag)
        }
        
        private func logoutSDK() {
            guard onlineRelay.value == .online else {
                return
            }
            
            rtmKit?.logout(completion: { [weak self] (code) in
                guard code == .ok else {
                    return
                }
                self?.onlineRelay.accept(.offline)
            })
            
        }
        
        private func rtmJoinChannel(_ channel: String) -> Single<String> {
            
            guard let rtmChannel = rtmKit?.createChannel(withId: channel, delegate: self) else {
                return Single.error(MsgError(code: 500, msg:  R.string.localizable.amongChatHomeEnterRoomFailed()))
            }
            
            return Single<String>.create { [weak self] (subscriber) -> Disposable in
                
                guard let `self` = self else {
                    subscriber(.error(MsgError(code: 500, msg:  R.string.localizable.amongChatHomeEnterRoomFailed())))
                    return Disposables.create()
                }
                
                
                cdPrint("joinChannel: \(channel)")
                rtmChannel.join { (code) in
                    guard code == .channelErrorOk else {
                        subscriber(.error(MsgError(code: 500, msg:  R.string.localizable.amongChatHomeEnterRoomFailed())))
                        return
                    }
                    cdPrint("joinChannel: \(channel) code: \(code.rawValue)")
                    self.rtmChannel = rtmChannel
                    subscriber(.success(channel))
                }
                
                return Disposables.create()
            }
            
        }
        
        func joinChannel(_ channel: String) {
            onlineRelay.filter { $0 == .online }.take(1)
                .flatMap { [weak self] (_) -> Single<String> in
                    guard let `self` = self else {
                        return Single.error(MsgError(code: 500, msg: R.string.localizable.amongChatHomeEnterRoomFailed()))
                    }
                    return self.rtmJoinChannel(channel)
                }
                .subscribe(onNext: { [weak self] (channelId) in
                    cdPrint("joinChannel: \(channelId)")
                    self?.joinedSubject.accept(true)
                })
                .disposed(by: bag)
        }
        
        func leaveChannel(_ channelId: String) {
            cdPrint("clean: \(channelId)")
            joinedSubject.accept(false)
            rtmChannel?.leave(completion: { (code) in
                cdPrint("clean leave: \(code.rawValue)")
                guard code == .ok else {
                    return
                }
            })
            rtmKit?.destroyChannel(withId: channelId)
        }
        
        func sendChannelMessage(_ message: String) -> Single<Bool> {
            
            return Single<Bool>.create { [weak self] (subsciber) -> Disposable in
                let rtmMessage = AgoraRtmMessage(text: message)
                
                self?.rtmChannel?.send(rtmMessage, sendMessageOptions: AgoraRtmSendMessageOptions(), completion: { (code) in
                    subsciber(.success(code == .errorOk))
                })
                
                return Disposables.create {
                    
                }
            }
            
        }
        
    }
    
}

extension AmongChat.Room.IMManager {
    
    private enum LoginStatus {
        case online, offline
    }
    
}

// MARK: AgoraRtmDelegate
extension AmongChat.Room.IMManager: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        cdPrint("connectionStateChanged: \(state.rawValue) reason: \(reason.rawValue)")
    }
    
    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        cdPrint("receive peer message: \(message) peer: \(peerId)")
        newPeerMessageSubject.onNext((message, peerId))
    }
}

// MARK: AgoraRtmChannelDelegate
extension AmongChat.Room.IMManager: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        cdPrint("memberJoined: \(member.channelId) \(member.userId)")
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        cdPrint("memberLeft: \(member.channelId) \(member.userId)")
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        cdPrint("messageReceived: \(member.channelId + "  " + member.userId + " text: " +  message.text)")
        newChannelMessageSubject.onNext((message, member))
    }
    
    func channel(_ channel: AgoraRtmChannel, memberCount count: Int32) {
        cdPrint("memberCount: \(count)")

    }
}

