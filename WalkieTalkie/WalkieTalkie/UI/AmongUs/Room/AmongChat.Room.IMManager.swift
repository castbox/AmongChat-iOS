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

extension AmongChat.Room {
    
    class IMManager: NSObject {
        
        private var rtmKit: AgoraRtmKit?
        private let onlineSubject = BehaviorSubject<LoginStatus>(value: .offline)
        private var rtmChannel: AgoraRtmChannel?
        private let joinedSubject = BehaviorSubject<Bool>(value: false)
        private let newMessageSubject = PublishSubject<(AgoraRtmMessage, AgoraRtmMember)>()
        private let channelId: String
        
        private let bag = DisposeBag()
        
        var newMessageObservable: Observable<(AgoraRtmMessage, AgoraRtmMember)> {
            return newMessageSubject.asObservable()
        }
        
        var joinedChannelSignal: Observable<Bool> {
            return joinedSubject.asObservable()
        }
        
        init(with channelId: String) {
            rtmKit = AgoraRtmKit.init(appId: KeyCenter.AppId, delegate: nil)
            self.channelId = channelId
            super.init()
            rtmKit?.agoraRtmDelegate = self
            bindEvents()
            loginSDK()
        }
        
        deinit {
            clean()
        }
        
        private func bindEvents() {
            onlineSubject
                .filter { $0 == .online }
                .take(1)
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    self.joinChannel(self.channelId)
                })
                .disposed(by: bag)
        }
        
        private func loginSDK() {
            guard let status = try? onlineSubject.value(),
                  status == .offline else {
                return
            }
            
            rtmKit?.login(byToken: KeyCenter.RtmToken, user: String(Constants.sUserId), completion: { [weak self] (code) in
                self?.onlineSubject.onNext(code == .ok ? .online : .offline)
            })
            
        }
        
        private func logoutSDK() {
            guard let status = try? onlineSubject.value(),
                  status == .online else {
                return
            }
            
            rtmKit?.logout(completion: { (code) in
                guard code == .ok else {
                    return
                }
            })
            
        }
        
        
        private func joinChannel(_ channel: String) {
            
            guard let rtmChannel = rtmKit?.createChannel(withId: channel, delegate: self) else { return }
            
            rtmChannel.join { [weak self] (code) in
                guard code == .channelErrorOk else {
                    return
                }
                self?.joinedSubject.onNext(true)
            }
            
            self.rtmChannel = rtmChannel
        }
        
        private func clean() {
            rtmChannel?.leave(completion: { (code) in
                guard code == .ok else {
                    return
                }
            })
            rtmKit?.destroyChannel(withId: channelId)
            logoutSDK()
        }
        
        func send(message: String) -> Single<Bool> {
            
            return Observable<Bool>.create { [weak self] (subsciber) -> Disposable in
                let rtmMessage = AgoraRtmMessage(text: message)
                
                self?.rtmChannel?.send(rtmMessage, sendMessageOptions: AgoraRtmSendMessageOptions(), completion: { (code) in
                    
                    subsciber.onNext(code == .errorOk)
                    subsciber.onCompleted()
                    
                })
                
                return Disposables.create {
                    
                }
            }
            .asSingle()
            
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
        
    }
}

// MARK: AgoraRtmChannelDelegate
extension AmongChat.Room.IMManager: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        newMessageSubject.onNext((message, member))
    }
}

