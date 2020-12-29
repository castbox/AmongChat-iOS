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

extension AmongChat.Home {
    
    class RelationViewModel {
        
        private let bag = DisposeBag()
        
        private let playingsSubject = BehaviorSubject<[PlayingViewModel]>(value: [])
        
        private let suggestionsSubject = BehaviorSubject<[PlayingViewModel]>(value: [])
                
        var dataSource: Observable<[[PlayingViewModel]]> {
            return Observable.combineLatest(playingsSubject, suggestionsSubject)
                .map { playings, suggestions in
                    [playings, suggestions]
                }
                .observeOn(MainScheduler.asyncInstance)
        }
        
        init() {
            Request.friendsPlayingList()
                .subscribe(onSuccess: { [weak self] (playingList) in
                    self?.playingsSubject.onNext(playingList.map({
                        PlayingViewModel(with: $0)
                    }))
                    
                }, onError: { [weak self] (error) in
                    self?.playingsSubject.onError(error)
                })
                .disposed(by: bag)
            
            Request.suggestionUserList()
                .subscribe(onSuccess: { [weak self] (playingList) in
                    self?.suggestionsSubject.onNext(playingList.map({
                        PlayingViewModel(with: $0)
                    }))
                }, onError: { [weak self] (error) in
                    self?.suggestionsSubject.onError(error)
                })
                .disposed(by: bag)
            
        }
        
    }
    
    class PlayingViewModel {
        
        private let playingModel: Entity.PlayingUser
        
        init(with model: Entity.PlayingUser) {
            playingModel = model
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
        
    }
    
}
