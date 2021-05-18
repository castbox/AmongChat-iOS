//
//  NoticeManager.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import WCDBSwift
import RxSwift
import RxCocoa

private let noticeTableName = Database.TableName.notice.rawValue
private let messageBodyTableName = Database.TableName.messageBody.rawValue

class NoticeManager {
    
    static let shared = NoticeManager()
            
    private let database = Database.shared
    
    func addNoticeList(_ noticeList: [Entity.Notice]) -> Single<Void> {
        
        guard noticeList.count > 0 else {
            return Single<Void>.just(())
        }
        
        return database.mapTransactionToSingle { (db) in
            try db.insertOrReplace(objects: noticeList, intoTable: noticeTableName)
        }
        .flatMap { [weak self] in
            
            guard let `self` = self else {
                return Single<Void>.just(())
            }
            
            return self.addMessgeBodyList(noticeList.map({ $0.message }))
        }
    }
    
    func addMessgeBodyList(_ messageList: [Entity.NoticeMessage]) -> Single<Void> {
        
        let messages: [Entity.NoticeMessage] = messageList.compactMap {
            guard let _ = $0.objType,
                  let _ = $0.objId else {
                return nil
            }
            return $0
        }
        
        guard messages.count > 0 else {
            return Single<Void>.just(())
        }
        
        return database.mapTransactionToSingle { (db) in
            try db.insertOrReplace(objects: messages,
                                   on: [Entity.NoticeMessage.Properties.img, Entity.NoticeMessage.Properties.title],
                                   intoTable: messageBodyTableName)
        }
    }
    
    func queryMessageBody(objType: String, objId: String) -> Single<Entity.NoticeMessage?> {
        return database.mapTransactionToSingle { (db) in
            let ex = Entity.NoticeMessage.Properties.objType == objType && Entity.NoticeMessage.Properties.objId == objId
            return try db.getObject(fromTable: messageBodyTableName,
                                    where: ex)
        }
    }
    
    func updateMessageBody(_ message: Entity.NoticeMessage) -> Single<Void> {
        return database.mapTransactionToSingle { (db) in
            guard let objId = message.objId, let objType = message.objType else {
                return
            }
            let ex = Entity.NoticeMessage.Properties.objType == objType && Entity.NoticeMessage.Properties.objId == objId
            try db.update(table: messageBodyTableName,
                          on: [Entity.NoticeMessage.Properties.img, Entity.NoticeMessage.Properties.title],
                          with: message,
                          where: ex)
        }
        .do(onSuccess: { [weak self] (_) in
            guard let `self` = self,
                let type = message.objType,
                  let objId = message.objId else { return }
            NotificationCenter.default.post(name: self.messageBodyUpdateNotification(objType: type, objId: objId),
                                            object: nil)
        })
        
    }
    
    private func messageBodyUpdateNotification(objType: String, objId: String) -> Notification.Name {
        return Notification.Name("among.chat.notice.message.body.update-\(objType)-\(objId)")
    }
    
    func messageBodyObservable(objType: String, objId: String) -> Observable<Entity.NoticeMessage?> {
        
        return NotificationCenter.default.rx.notification(messageBodyUpdateNotification(objType: objType, objId: objId))
            .startWith(Notification(name: messageBodyUpdateNotification(objType: objType, objId: objId)))
            .flatMap({ [weak self] (_) -> Observable<Entity.NoticeMessage?> in
                guard let `self` = self else {
                    return Observable.just(nil)
                }
                
                return self.queryMessageBody(objType: objType, objId: objId)
                    .asObservable()
            })
        
    }
    
    func noticeList(limit: Int? = nil, offset: Int? = nil) -> Single<[Entity.Notice]> {
        
        return database.mapTransactionToSingle { (db) in
            try db.getObjects(fromTable: noticeTableName,
                              orderBy: [Entity.Notice.Properties.ms.asOrder(by: .descending)],
                              limit: limit,
                              offset: offset)
        }
        
    }
    
    func latestNotice() -> Single<Entity.Notice?> {
        return database.mapTransactionToSingle { (db) in
            try db.getObject(fromTable: noticeTableName,
                             orderBy: [Entity.Notice.Properties.ms.asOrder(by: .descending)])
        }
    }
    
}
