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

extension AmongChat.Room {
    
    class IMViewModel {
        
        private typealias MessageViewModel = AmongChat.Room.MessageViewModel
        
        private let channelId: String
        private let imManager: IMManager
        private let messagesRelay = BehaviorRelay<[MessageViewModel]>(value: [])
        
        private let bag = DisposeBag()
        
        var messagesObservable: Observable<[AmongChat.Room.MessageViewModel]> {
            return messagesRelay.asObservable()
        }
        
        var imReadySignal: Observable<Bool> {
            return imManager.joinedChannelSignal
        }
        
        init(with channelId: String) {
            self.channelId = channelId
            self.imManager = AmongChat.Room.IMManager(with: channelId)
            
            bindEvents()
        }
                
    }
    
}

extension AmongChat.Room.IMViewModel {
        
    private func appendNewMessage(_ message: AgoraRtmMessage, user: AgoraRtmMember) {
        
        let userViewModel: ChannelUserViewModel
        
        if let user = ChannelUserListViewModel.shared.channelUserViewModelList.first(where: { "\($0.channelUser.uid)" == user.userId }) {
            userViewModel = user
        } else {
            userViewModel = ChannelUserViewModel(with: ChannelUser.randomUser(uid: UInt(user.userId) ?? 0), firestoreUser: nil)
        }

        let messageVM = MessageViewModel(user: userViewModel, text: message.text)
        
        var messages = messagesRelay.value
        messages.append(messageVM)
        messagesRelay.accept(messages)
    }
    
    private func bindEvents() {
        
        imManager.newMessageObservable
            .subscribe(onNext: { [weak self] agoraRtmMessage, agoraRtmMember in
                self?.appendNewMessage(agoraRtmMessage, user: agoraRtmMember)
            })
            .disposed(by: bag)
    }
    
    func sendMessage(_ text: String) {
        
        imManager.send(message: text)
            .catchErrorJustReturn(false)
            .subscribe(onSuccess: { [weak self] (success) in
                guard let `self` = self,
                    success else { return }
                
                let msg = AgoraRtmMessage(text: text)
                let user = AgoraRtmMember()
                user.userId = "\(Constants.sUserId)"
                user.channelId = self.channelId
                
                self.appendNewMessage(msg, user: user)
            })
            .disposed(by: bag)
        
    }
        
}

extension AmongChat.Room {
    
    struct MessageViewModel {
        let user: ChannelUserViewModel
        let text: String
    }
    
}
