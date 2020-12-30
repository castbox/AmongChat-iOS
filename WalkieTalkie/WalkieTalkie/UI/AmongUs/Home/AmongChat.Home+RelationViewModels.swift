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
        
        private typealias IMManager = AmongChat.Room.IMManager
        
        private let bag = DisposeBag()
        
        private let playingsRelay = BehaviorRelay<[PlayingViewModel]>(value: [])
        
        private let suggestionsRelay = BehaviorRelay<[PlayingViewModel]>(value: [])
        
        private let imManager = IMManager.shared
                
        var dataSource: Observable<[[PlayingViewModel]]> {
            return Observable.combineLatest(playingsRelay, suggestionsRelay)
                .map { playings, suggestions in
                    [playings, suggestions]
                }
                .observeOn(MainScheduler.asyncInstance)
        }
        
        init() {
            imManager.newPeerMessageObservable
                .subscribe(onNext: { [weak self] message, sender in
                    self?.handleIMMessage(message: message, sender: sender)
                })
                .disposed(by: bag)
            
            refreshOnlineFriends()
            refreshSuggestionUsers()
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
                
        func refreshOnlineFriends() {
            Request.friendsPlayingList()
                .subscribe(onSuccess: { [weak self] (playingList) in
                    self?.playingsRelay.accept(playingList.map({
                        PlayingViewModel(with: $0)
                    }))
                })
                .disposed(by: bag)
        }
        
        func refreshSuggestionUsers() {
            Request.suggestionUserList()
                .subscribe(onSuccess: { [weak self] (playingList) in
                    self?.suggestionsRelay.accept(playingList.map({
                        PlayingViewModel(with: $0)
                    }))
                })
                .disposed(by: bag)
        }
        
        func updateSuggestionUser(user: PlayingViewModel) {
            
            var suggestionUsers = suggestionsRelay.value
            suggestionUsers.removeAll { $0.uid == user.uid }
            
            if suggestionUsers.count == 0 {
                refreshSuggestionUsers()
            }
            
            var onlineFriends = playingsRelay.value
            onlineFriends.append(user)
            
            suggestionsRelay.accept(suggestionUsers)
            playingsRelay.accept(onlineFriends)
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
        
        var userName: String? {
            return playingModel.user.name
        }
        
        var userAvatarUrl: String? {
            return playingModel.user.pictureUrl
        }
                
        var playingStatus: String? {
            
            guard let room = playingModel.room else {
                return nil
            }
            
            return R.string.localizable.amongChatHomeFriendsInChannel(room.topicName)
        }
        
        var joinable: Bool {
            
            guard let room = playingModel.room else {
                return false
            }
            
            return room.state == .public
        }
        
        var roomId: String? {
            return playingModel.room?.roomId
        }
        
        var roomTopicId: String? {
            return playingModel.room?.topicId
        }
        
    }
    
}
