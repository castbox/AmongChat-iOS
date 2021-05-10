//
//  DMManager.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 08/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import WCDBSwift
import RxSwift
import RxCocoa

private let dmConversationTableName = Database.TableName.dmConversation.rawValue
private let dmMessagesTableName = Database.TableName.dmMessages.rawValue

class DMManager {
    
    static let shared = DMManager()
    
    let conversactionUpdateReplay = BehaviorRelay<Entity.DMConversation?>(value: nil)
    
//    let messageUpdateReplay = BehaviorRelay<Entity.DMConversation?>(value: nil)
            
    private let database = Database.shared
    private var messageObservables: [String: PublishSubject<Void>] = [:]
    
    init() {
        _ = IMManager.shared.newPeerMessageObservable
            .filter { $0.msgType == .dm }
            .subscribe(onNext: { [weak self] message in
                guard let msg = message as? Entity.DMMessage else {
                    return
                }
                //insert new
                _ = self?.add(message: msg)
                    .subscribe()
            })
    }
    
    func insertOrReplace(message: Entity.DMMessage) {
        _ = add(message: message)
            .subscribe()
    }
    
    func add(message: Entity.DMMessage) -> Single<Void> {
        //1. replace or add conversation
        return queryConversation(fromUid: message.fromUid)
            .flatMap { [unowned self] item -> Single<Void> in
                var conversation: Entity.DMConversation {
                    guard var item = item else {
                        return message.toConversation()
                    }
                    //消息为本人发送，则只更新 conversation body 内容
                    if message.fromUser.isLoginUser {
                        item.message.body = message.body
                    } else {
                        item.message = message
                        item.unreadCount += 1
                    }
                    item.lastMsgMs = Date().timeIntervalSince1970
                    return item
                }
                return database.mapTransactionToSingle { db in
                    try db.insertOrReplace(objects: conversation, intoTable: dmConversationTableName)
                    try db.insertOrReplace(objects: message, intoTable: dmMessagesTableName)
                }
                .do(onSuccess: { [unowned self] in
                    self.conversactionUpdateReplay.accept(conversation)
                    //
                    if let subject = messageObservables[message.fromUid] {
                        subject.onNext(())
                    }
                })
            }
    }
    
    func observableMessages(for uid: String) -> Observable<Void> {
        guard messageObservables[uid] == nil else {
            return .empty()
        }
        return Observable.create { [unowned self] observer in
            let subject = PublishSubject<Void>()
            _ = subject.subscribe(onNext: {
                observer.onNext(())
            })
            messageObservables[uid] = subject
            return Disposables.create { [unowned self] in
                self.messageObservables.removeValue(forKey: uid)
            }
        }
    }
    
//
//    func add(messgeBody messageList: [Entity.NoticeMessage]) -> Single<Void> {
//
//        let messages: [Entity.NoticeMessage] = messageList.compactMap {
//            guard let _ = $0.objType,
//                  let _ = $0.objId else {
//                return nil
//            }
//            return $0
//        }
//
//        guard messages.count > 0 else {
//            return Single<Void>.just(())
//        }
//
//        return database.mapTransactionToSingle { (db) in
//            try db.insertOrReplace(objects: messages,
//                                   on: [Entity.NoticeMessage.Properties.img, Entity.NoticeMessage.Properties.title],
//                                   intoTable: messageBodyTableName)
//        }
//    }
    
    func queryConversation(fromUid: String) -> Single<Entity.DMConversation?> {
        return database.mapTransactionToSingle { (db) in
            let ex = Entity.DMConversation.Properties.fromUid == fromUid
            return try db.getObject(fromTable: dmConversationTableName,
                                    where: ex,
                                    orderBy: [Entity.DMConversation.Properties.lastMsgMs.asOrder(by: .descending)])
        }
    }
    
    func conversations(limit: Int? = nil, offset: Int? = nil) -> Single<[Entity.DMConversation]> {
        return database.mapTransactionToSingle { (db) in
            try db.getObjects(fromTable: dmConversationTableName,
                              orderBy: [Entity.DMConversation.Properties.lastMsgMs.asOrder(by: .descending)],
                              limit: limit,
                              offset: offset)
        }

    }
    
    func messages(for uid: String, limit: Int? = nil, offset: Int? = nil) -> Single<[Entity.DMMessage]> {
        let ex = Entity.DMMessage.Properties.fromUid == uid && Entity.DMMessage.Properties.status != "empty"
        return database.mapTransactionToSingle { (db) in
            try db.getObjects(fromTable: dmMessagesTableName,
                              where: ex,
                              orderBy: [Entity.DMMessage.Properties.ms.asOrder(by: .descending)],
                              limit: limit,
                              offset: offset)
        }

    }
    
//
//    func queryMessageBody(objType: String, objId: String) -> Single<Entity.NoticeMessage?> {
//        return database.mapTransactionToSingle { (db) in
//            let ex = Entity.NoticeMessage.Properties.objType == objType && Entity.NoticeMessage.Properties.objId == objId
//            return try db.getObject(fromTable: messageBodyTableName,
//                                    where: ex)
//        }
//    }
//
//    func updateMessageBody(_ message: Entity.NoticeMessage) -> Single<Void> {
//        return database.mapTransactionToSingle { (db) in
//            guard let objId = message.objId, let objType = message.objType else {
//                return
//            }
//            let ex = Entity.NoticeMessage.Properties.objType == objType && Entity.NoticeMessage.Properties.objId == objId
//            try db.update(table: messageBodyTableName,
//                          on: [Entity.NoticeMessage.Properties.img, Entity.NoticeMessage.Properties.title],
//                          with: message,
//                          where: ex)
//        }
//        .do(onSuccess: { [weak self] (_) in
//            guard let `self` = self,
//                let type = message.objType,
//                  let objId = message.objId else { return }
//            NotificationCenter.default.post(name: self.messageBodyUpdateNotification(objType: type, objId: objId),
//                                            object: nil)
//        })
//
//    }
//
//    private func messageBodyUpdateNotification(objType: String, objId: String) -> Notification.Name {
//        return Notification.Name("among.chat.notice.message.body.update-\(objType)-\(objId)")
//    }
//
//    func messageBodyObservable(objType: String, objId: String) -> Observable<Entity.NoticeMessage?> {
//
//        return NotificationCenter.default.rx.notification(messageBodyUpdateNotification(objType: objType, objId: objId))
//            .startWith(Notification(name: messageBodyUpdateNotification(objType: objType, objId: objId)))
//            .flatMap({ [weak self] (_) -> Observable<Entity.NoticeMessage?> in
//                guard let `self` = self else {
//                    return Observable.just(nil)
//                }
//
//                return self.queryMessageBody(objType: objType, objId: objId)
//                    .asObservable()
//            })
//
//    }
//
//    func noticeList(limit: Int? = nil, offset: Int? = nil) -> Single<[Entity.Notice]> {
//
//        return database.mapTransactionToSingle { (db) in
//            try db.getObjects(fromTable: noticeTableName,
//                              orderBy: [Entity.Notice.Properties.ms.asOrder(by: .descending)],
//                              limit: limit,
//                              offset: offset)
//        }
//
//    }
//
//    func latestNotice() -> Single<Entity.Notice?> {
//        return database.mapTransactionToSingle { (db) in
//            try db.getObject(fromTable: noticeTableName,
//                             orderBy: [Entity.Notice.Properties.ms.asOrder(by: .descending)])
//        }
//    }
    
}
