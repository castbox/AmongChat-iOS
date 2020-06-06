//
//  RoomViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class RoomViewModel {
    let bag = DisposeBag()
    var shouldShowEmojiHandle: (([String]) -> Void)?
    var observeEmojiAtRoom: Room?
    private var emojiObserveIgnoredKeys: [String] = []
    
    private var emojiObserverDispose: Disposable?
    
    func requestEnterRoom() {
        ApiManager.default.reactiveRequest(.enterRoom)
            .subscribe(onNext: { _ in
                
            })
            .disposed(by: bag)
    }
    
    func addEmojiObserveIgnored(key: String?) {
        guard let key = key else {
            return
        }
        emojiObserveIgnoredKeys.append(key)
    }
    
    func observerEmoji(at room: Room?, searchViewModel: SearchViewModel, emojiHandler: @escaping ([String]) -> Void) {
        observeEmojiAtRoom = room
        guard let room = room else {
            removeEmojiObserver()
            return
        }
        addEmojiObserveIgnored(key: room.emoji?.updated)
        emojiObserverDispose =
            FireStore.shared.observerEmoji(at: room.name)
//            searchViewModel.dataSourceSubject
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
//            .map { rooms -> Room? in
//                return rooms.first(where: { $0.name == room.name })
//            }
            .filterNil()
            .distinctUntilChanged { (previous, new) -> Bool in
                return previous.emoji?.updated == new.emoji?.updated
            } //有变化
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] room in
                guard let `self` = self,
                    let emoji = room.emoji?.chars,
                    !emoji.isEmpty,
                    let updated = room.emoji?.updated,
                    !self.emojiObserveIgnoredKeys.contains(updated)  else {
                        return
                }
                emojiHandler(emoji)
            })
        emojiObserverDispose?.disposed(by: bag)
    }
    
    func removeEmojiObserver() {
        observeEmojiAtRoom = nil
        emojiObserverDispose?.dispose()
        emojiObserverDispose = nil
        emojiObserveIgnoredKeys.removeAll()
    }
}
