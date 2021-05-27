//
//  AmongChat.Home.ConversationViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension AmongChat.Home {
    
    class ConversationViewModel {
        let bag = DisposeBag()
//        private var dataSource: [Any] = []
        let dataSourceReplay = BehaviorRelay<[Any]>(value: [])
        let haveNewInteractiveMsgReplay = BehaviorRelay<Bool>(value: false)
        
        init() {
            let conversationListObservable = DMManager.shared.conversactionUpdateReplay
                .startWith(nil)
                .flatMap { item -> Single<[Entity.DMConversation]> in
                    return DMManager.shared.conversations()
                }
                .do(onNext: { items in
                    let unreadCount = items.reduce(0, { $0 + $1.unreadCount })
                    Settings.shared.hasUnreadMessageRelay.accept(unreadCount > 0)
                })
            
            let interactiveMsgObservable = haveNewInteractiveMsgReplay
                .map { Entity.DMSystemConversation(style: .interactive, isRead: $0) }
                .map { [$0] }
            
            Observable.combineLatest(conversationListObservable, interactiveMsgObservable)
                .map { (userConversation, systems) -> [Any] in
                    var arrays: [Any] = systems
                    arrays.append(contentsOf: userConversation)
                    return arrays
                }
                .observeOn(MainScheduler.asyncInstance)
                .bind(to: dataSourceReplay)
                .disposed(by: bag)
        }
    }
}
