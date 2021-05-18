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
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[DMManager]-\(message)")
}

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
        
        updateLoadingMsgToFailedStatus()
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
                    item.message.ms = message.ms
                    item.lastMsgMs = Date().timeIntervalSince1970
                    return item
                }
                return database.mapTransactionToSingle { db in
                    try db.insertOrReplace(objects: conversation, intoTable: dmConversationTableName)
                    try db.insertOrReplace(objects: message, intoTable: dmMessagesTableName)
                }
                .do(onSuccess: { [unowned self] in
                    self.conversactionUpdateReplay.accept(conversation)
                    self.notifyMessagesUpdated(of: message.fromUid)
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
    
    func clearUnreadCount(with conversation: Entity.DMConversation) -> Single<Entity.DMConversation> {
        var newItem = conversation
        newItem.unreadCount = 0
        return database.mapTransactionToSingle { (db) in
            try db.update(table: dmConversationTableName,
                          on: [Entity.DMConversation.Properties.unreadCount],
                          with: newItem,
                          where: Entity.DMConversation.Properties.fromUid == conversation.fromUid)
        }.map { newItem }
        .do(onSuccess: { [weak self] _ in
            self?.conversactionUpdateReplay.accept(newItem)
        })
    }
    
    func clearAllMessage(of uid: String) -> Single<Void> {
        return self.database.mapTransactionToSingle { (db) in
            try db.delete(fromTable: dmMessagesTableName, where: Entity.DMMessage.Properties.fromUid == uid)
        }
        .flatMap { [unowned self] _ in
            return self.queryConversation(fromUid: uid)
                .flatMap { [unowned self] item -> Single<Void> in
                    guard var conversation = item else {
                        return .just(())
                    }
                    conversation.message.body = Entity.DMMessageBody(type: .text)
                    return self.database.mapTransactionToSingle { db in
                        try db.insertOrReplace(objects: conversation, intoTable: dmConversationTableName)
                    }
                }
        }
        .do(onSuccess: { [weak self] _ in
            self?.conversactionUpdateReplay.accept(nil)
            self?.notifyMessagesUpdated(of: uid)
        })
    }
    
    func update(profile: Entity.DMProfile) {
        _ = observeUpdate(profile: profile)
            .subscribe()
    }
    
    func observeUpdate(profile: Entity.DMProfile) -> Single<Void> {
        guard profile.uid.string != Settings.loginUserId?.string else {
            return .just(())
        }

        return self.queryConversation(fromUid: profile.uid.string)
            .flatMap { [unowned self] item -> Single<Void> in
                guard var conversation = item else {
                    return .just(())
                }
                let message = conversation.message.update(profile: profile)
                conversation.message = message
                return self.database.mapTransactionToSingle { db in
                    try db.insertOrReplace(objects: conversation, intoTable: dmConversationTableName)
                    try db.update(table: dmMessagesTableName, on: [Entity.DMMessage.Properties.fromUser], with: message, where: Entity.DMMessage.Properties.fromUid == profile.uid.string && Entity.DMMessage.Properties.isFromMe == false) //更新用户头像
                }
            }
            .do(onSuccess: { [weak self] _ in
                self?.conversactionUpdateReplay.accept(nil)
                self?.notifyMessagesUpdated(of: profile.uid.string)
            })
    }
    
    func deleteConversation(of uid: String) -> Single<Void> {

        return self.database.mapTransactionToSingle { (db) in
            try db.delete(fromTable: dmConversationTableName, where: Entity.DMConversation.Properties.fromUid == uid)
            try db.delete(fromTable: dmMessagesTableName, where: Entity.DMMessage.Properties.fromUid == uid)
        }
        .do(onSuccess: { [weak self] _ in
            self?.conversactionUpdateReplay.accept(nil)
        })
    }
}

private extension DMManager {
    func updateLoadingMsgToFailedStatus() {
       guard let profile = Settings.loginUserProfile?.dmProfile else {
           return
       }
       var failedMessage = Entity.DMMessage.emptyMessage(for: profile)
       failedMessage.status = .failed
        //case sending case downloading
        
        let ex = (Entity.DMMessage.Properties.status == "sending" || Entity.DMMessage.Properties.status == "downloading")
            //&& Entity.DMMessage.Properties.isFromMe == true
       _ = database.mapTransactionToSingle { db in
           try db.update(table: dmMessagesTableName, on: [Entity.DMMessage.Properties.status], with: failedMessage, where: ex)
       }
       .subscribe()
   }
    
    func notifyMessagesUpdated(of uid: String) {
        if let subject = messageObservables[uid] {
            subject.onNext(())
        }
    }

}
