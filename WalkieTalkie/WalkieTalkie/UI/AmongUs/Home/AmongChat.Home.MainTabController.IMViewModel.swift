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
        
        private let imManager = IMManager.shared
        
        private let bag = DisposeBag()
        
        private let invitationSubject = PublishSubject<(Entity.UserProfile, Peer.FriendUpdatingInfo.Room)>()
        
        private let invitationRecommendSubject = PublishSubject<(Entity.UserProfile, Peer.FriendUpdatingInfo.Room)>()
        
        var invitationObservable: Observable<(Entity.UserProfile, Peer.FriendUpdatingInfo.Room)> {
            return invitationSubject.asObservable()
        }

        var invitationRecommendObservable: Observable<(Entity.UserProfile, Peer.FriendUpdatingInfo.Room)> {
            return invitationRecommendSubject.asObservable()
        }
        
        init() {
            imManager.newPeerMessageObservable
                .subscribe(onNext: { [weak self] message in
                    self?.handleIMMessage(message: message)
                })
                .disposed(by: bag)
            
            _ = DMManager.shared
            
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
        private let roomInvitationInviteStranger = "AC:PEER:InviteStranger"

        private func handleIMMessage(message: PeerMessage) {
            
            
            switch message.msgType {
            case .roomInvitation, .roomInvitationInviteStranger:

                guard let invitationMsg = message as? Peer.FriendUpdatingInfo,
                      let room = invitationMsg.room else {
                    return
                }

                if invitationMsg.msgType == .roomInvitation {
                    invitationSubject.onNext((invitationMsg.user, room))
                } else if invitationMsg.msgType == .roomInvitationInviteStranger {
                    invitationRecommendSubject.onNext((invitationMsg.user, room))
                }
                
            case .unreadNotice, .unreadGroupApply:
                Settings.shared.hasUnreadNoticeRelay.accept(true)
            case .unreadInteractiveMsg:
                Settings.shared.hasUnreadInteractiveMsgRelay.accept(true)
            default:
                ()
            }
            
        }
    }
    
    
    
}
