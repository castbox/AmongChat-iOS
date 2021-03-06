//
//  AmongChat.Room.IMViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/8.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AgoraRtmKit
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[IMViewModel]-\(message)")
}


extension AmongChat.Room {
    
    class IMViewModel {
        
        private let channelId: String
        private let imManager: IMManager
        private let messageRelay = BehaviorRelay<ChatRoomMessage?>(value: nil)
        
        private let bag = DisposeBag()
        
        var roomMessagesObservable: Observable<ChatRoomMessage> {
            return messageRelay.asObservable()
                .filterNilAndEmpty()
        }
        
        var peerMessagesObservable: Observable<PeerMessage> {
            return imManager.newPeerMessageObservable
//                .filterNilAndEmpty()
        }
        
        var imReadySignal: Observable<Bool> {
            return imManager.joinedChannelSignal
        }
        
        var imIsReady: Bool {
            return imManager.imIsReady
        }
        
        init(with channelId: String) {
            self.channelId = channelId
            self.imManager = IMManager.shared
            imManager.joinChannel(channelId)
            bindEvents()
        }
        
        deinit {
//            imManager.leaveChannel(channelId)
        }
        
        func leaveChannel() {
            imManager.leaveChannel(channelId)
        }
                
    }
    
}

extension AmongChat.Room.IMViewModel {
    
    private func bindEvents() {
        
        imManager.newChannelMessageObservable
            .debug("[newMessageObservable]", trimOutput: false)
            .observeOn(MainScheduler.asyncInstance)
//            .subscribe(onNext: { [weak self] message in
//                self?.appendNewMessage(message)
//            })
            .bind(to: messageRelay)
            .disposed(by: bag)
    }
    
    func sendText(message: ChatRoomMessage, completionHandler: CallBack? = nil) {
        guard let string = message.asString else {
            return
        }
        imManager.send(channelMessage: string)
            .catchErrorJustReturn(false)
            .subscribe(onSuccess: { _ in
                completionHandler?()
            })
            .disposed(by: bag)
        
    }
    
    func sendPeer(message: PeerMessage, to: Int, completionHandler: CallBack? = nil) {
        guard let string = message.asString else {
            return
        }
        imManager.sendPeer(message: string, to: to)
            .catchErrorJustReturn(false)
            .subscribe(onSuccess: { _ in
                completionHandler?()
            })
            .disposed(by: bag)

    }
    
        
}
