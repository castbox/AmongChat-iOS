//
//  ConversationViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 08/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Conversation {
    class MessageCellViewModel {
        let message: Entity.DMMessage
        let height: CGFloat
        let showTime: Bool
        let contentSize: CGSize
        let sendFromMe: Bool
        
        init(message: Entity.DMMessage, showTime: Bool) {
            self.message = message
            self.showTime = showTime
            self.sendFromMe = message.fromUser.uid == Settings.loginUserId?.int64
            //calculate height
            
//            switch message.body.msgType {
//            case .text:
                let maxWidth = Frame.Screen.width - 72 * 2
            let textSize = message.body.text?.boundingRect(with: CGSize(width: maxWidth, height: 1000), font: R.font.nunitoBold(size: 16)!) ?? CGSize(width: 0, height: 0)
            contentSize = textSize
            let topEdge: CGFloat = 18
            var height = contentSize.height + topEdge * 2
            if showTime {
                height += 27
            }
            self.height = height
//            case .gif:
//
//            case .voice:
//            }
        }
    }
}

extension Conversation {
    /**
     当天的消息，以每5分钟为一个跨度的显示时间；发送时间间隔大于5分钟显示时间，小于5分钟不显示；
     消息超过1天、小于1周，显示星期+收发消息的时间；
     消息大于1周，显示手机收发时间的日期。
     
     */
    class ViewModel {
        private var conversation: Entity.DMConversation
        
        private var dataSource: [MessageCellViewModel] = []
        
        let dataSourceReplay = BehaviorRelay<[MessageCellViewModel]>(value: [])
        
        private let bag = DisposeBag()
        
        //分级时间
        private var groupTime: Double = 0
        
        init(_ conversation: Entity.DMConversation) {
            self.conversation = conversation
            let uid = conversation.fromUid
            
            DMManager.shared.observableMessages(for: uid)
                .startWith(())
                .flatMap { item -> Single<[Entity.DMMessage]> in
                    return DMManager.shared.messages(for: uid)
                }
                .map { [weak self] items -> [MessageCellViewModel] in
                    guard let `self` = self else { return [] }
                    return items.map { message -> MessageCellViewModel in
                        if self.groupTime == 0 {
                            self.groupTime = message.timestamp
                        }
                        //大余5分钟则显示时间，
                        let showTimeLabel = (self.groupTime - message.timestamp) > 60 * 5
                        if showTimeLabel {
                            self.groupTime = message.timestamp
                        }
                        return MessageCellViewModel(message: message, showTime: showTimeLabel)
                    }
//                    //show time
                    
                }
                .observeOn(MainScheduler.asyncInstance)
                .bind(to: dataSourceReplay)
                .disposed(by: bag)
        }
    }
}
