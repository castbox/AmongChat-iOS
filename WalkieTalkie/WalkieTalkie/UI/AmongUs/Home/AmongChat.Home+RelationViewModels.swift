//
//  AmongChat.Home+RelationViewModels.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import AgoraRtmKit

extension AmongChat.Home {
    
    class RelationViewModel {
        struct Item {
            enum Group: Int {
                case playing
                case suggestContacts
                case suggestStrangers
            }
            
            var userLsit: [PlayingViewModel]
            let group: Group
            
        }
        
        private typealias IMManager = AmongChat.Room.IMManager
        
        private let bag = DisposeBag()
        
        private let playingsRelay = BehaviorRelay<[PlayingViewModel]>(value: [])
        
        private let suggestStrangerRelay = BehaviorRelay<[PlayingViewModel]>(value: [])
        
        private let suggestContactRelay = BehaviorRelay<[ContactViewModel]>(value: [])
        
        private let imManager = IMManager.shared
                
        var dataSource: Observable<[Item]> {
            return Observable.combineLatest(playingsRelay, suggestContactRelay, suggestStrangerRelay)
                .map { playings, contacts, strangers in
                    [Item(userLsit: playings, group: .playing), Item(userLsit: contacts, group: .suggestContacts), Item(userLsit: strangers, group: .suggestStrangers)]
                }
                .observeOn(MainScheduler.asyncInstance)
        }
        
        init() {
            imManager.newPeerMessageObservable
                .subscribe(onNext: { [weak self] message, sender in
                    self?.handleIMMessage(message: message, sender: sender)
                })
                .disposed(by: bag)
            let testArray = [Entity.ContactFriend(phone: "", name: "Wilson", count: 10),
             Entity.ContactFriend(phone: "", name: "WilsonYuan", count: 2),
             Entity.ContactFriend(phone: "", name: "XiaoMing", count: 112)]
                .map { ContactViewModel(with: $0) }
            suggestContactRelay.accept(testArray)
            
        }
        
        private let systemAgoraUid = Int(99999)
        private let friendsInfoMessageType = "AC:PEER:FriendsInfo"
        
        private func handleIMMessage(message: AgoraRtmMessage, sender: String) {
            
            guard sender == "\(systemAgoraUid)" else {
                return
            }
            
            guard message.type == .text,
                  let json = message.text.jsonObject(),
                  let friendInfo = JSONDecoder().mapTo(Entity.FriendUpdatingInfo.self, from: json),
                  friendInfo.messageType == friendsInfoMessageType else {
                return
            }
            
            var onlineFriends = playingsRelay.value
            
            if let idx = onlineFriends.firstIndex(where: { $0.uid == friendInfo.user.uid }) {
                if friendInfo.isOnline == false {
                    onlineFriends.removeAll { $0.uid == friendInfo.user.uid }
                } else {
                    onlineFriends.replaceSubrange(idx...idx, with: [PlayingViewModel(with: friendInfo.asPlayingUser())])
                }
            } else {
                if friendInfo.isOnline == true {
                    onlineFriends.append(PlayingViewModel(with: friendInfo.asPlayingUser()))
                }
            }
            playingsRelay.accept(onlineFriends)
        }
        
        func refreshData() {
            refreshOnlineFriends()
            refreshSuggestionUsers()
        }
                
        private func refreshOnlineFriends() {
            Request.friendsPlayingList()
                .subscribe(onSuccess: { [weak self] (playingList) in
                    self?.playingsRelay.accept(playingList.map({
                        PlayingViewModel(with: $0)
                    }))
                })
                .disposed(by: bag)
        }
        
        private func refreshSuggestionUsers() {
            Request.suggestionUserList()
                .subscribe(onSuccess: { [weak self] (playingList) in
                    self?.suggestStrangerRelay.accept(playingList.map({
                        PlayingViewModel(with: $0)
                    }))
                })
                .disposed(by: bag)
        }
        
        func updateSuggestionUser(user: PlayingViewModel) {
            
            var suggestionUsers = suggestStrangerRelay.value
            suggestionUsers.removeAll { $0.uid == user.uid }
            
            if suggestionUsers.count == 0 {
                refreshSuggestionUsers()
            }
            
            var onlineFriends = playingsRelay.value
            onlineFriends.append(user)
            
            suggestStrangerRelay.accept(suggestionUsers)
            playingsRelay.accept(onlineFriends)
        }
        
    }
    
    class ContactViewModel: PlayingViewModel {
        let contact: Entity.ContactFriend
        
        init(with contact: Entity.ContactFriend) {
            self.contact = contact
            //
            var user: Entity.UserProfile?
            decoderCatcher {
                user = try JSONDecoder().decodeAnyData(Entity.UserProfile.self, from: ["uid": 0])
            }
            super.init(with: Entity.PlayingUser(user: user!, room: nil))
        }
    }
    
    class PlayingViewModel {
        
        private let playingModel: Entity.PlayingUser
        
        init(with model: Entity.PlayingUser) {
            playingModel = model
        }
        
        var uid: Int {
            return playingModel.user.uid
        }
        
        var userName: NSAttributedString? {
            return playingModel.user.nameWithVerified()
        }
        
        var userAvatarUrl: String? {
            return playingModel.user.pictureUrl
        }
                
        var playingStatus: String {
            
            guard let room = playingModel.room else {
                return R.string.localizable.socialStatusOnline().lowercased()
            }
            
            return R.string.localizable.amongChatHomeFriendsInChannel(room.topicName)
        }
        
        var roomState: Entity.RoomPublicType? {
            return playingModel.room?.state
        }
        
        var roomId: String? {
            return playingModel.room?.roomId
        }
        
        var roomTopicId: String? {
            return playingModel.room?.topicId
        }
        
    }
    
}
