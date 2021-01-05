//
//  AmongChat.Home.MainTabController.IMViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import AgoraRtmKit

extension AmongChat.Home.MainTabController {
    
    class IMViewModel {
        
        private let imManager = AmongChat.Room.IMManager.shared
        
        private let bag = DisposeBag()
        
        private let invitationSubject = PublishSubject<(Entity.UserProfile, Entity.FriendUpdatingInfo.Room)>()
        
        var invitationObservable: Observable<(Entity.UserProfile, Entity.FriendUpdatingInfo.Room)> {
            return invitationSubject.asObservable()
        }
        
        init() {
            imManager.newPeerMessageObservable
                .subscribe(onNext: { [weak self] message, sender in
                    self?.handleIMMessage(message: message, sender: sender)
                })
                .disposed(by: bag)
            
            #if DEBUG
//            let _ = Observable<Int>.timer(.seconds(0), period: .seconds(5), scheduler: MainScheduler.instance)
//                    .take(5)
//                    .subscribe(onNext: { count in
//                        self.invitationSubject.onNext((Settings.shared.amongChatUserProfile.value!, Entity.FriendUpdatingInfo.Room.defaultRoom()))
//                    }, onCompleted: {
//
//                    })
            #endif
        }
        
        private let roomInvitationMessageType = "AC:PEER:Invite"
        
        private func handleIMMessage(message: AgoraRtmMessage, sender: String) {
            
            guard message.type == .text,
                  let json = message.text.jsonObject(),
                  let invitationMsg = JSONDecoder().mapTo(Entity.FriendUpdatingInfo.self, from: json),
                  invitationMsg.messageType == roomInvitationMessageType,
                  let room = invitationMsg.room else {
                return
            }
            
            invitationSubject.onNext((invitationMsg.user, room))
            
        }
    }
    
    
    
}
