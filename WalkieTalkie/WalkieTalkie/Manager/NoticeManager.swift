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

private let noticeTableName = "notices"
private let messageBodyTableName = "messges"

class NoticeManager {
    
    static let shared = NoticeManager()
    
    private let dbIOQueue = DispatchQueue.init(label: "among.chat.notice.db.io", qos: .userInitiated)
        
    private var database: Database? = nil {
        didSet {
            oldValue?.close()
        }
    }
    
    private init() {
        
        let _ = Settings.shared.loginResult.replay()
            .filterNil()
            .subscribe(onNext: { [weak self] (loginUser) in
                
                guard let `self` = self else { return }
                                
                let database = Database(withFileURL: self.dbURL(of: loginUser.uid))
                database.setTokenizes([.WCDB])
                
                do {
                    try database.create(table: noticeTableName, of: Entity.Notice.self)
                    try database.create(table: messageBodyTableName, of: Entity.NoticeMessage.self)
                    self.database = database
                } catch let error {
                    cdPrint("create table error \(error.localizedDescription)")
                }
                
            })
        
    }
    
    private func dbURL(of user: Int) -> URL {
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask,
                                                         true).last! + "/Notice/\(user)/Notice.db"
        return URL(fileURLWithPath: dbPath)
    }
    
    func addNoticeList(_ noticeList: [Entity.Notice]) -> Single<Void> {
        
        guard noticeList.count > 0 else {
            return Single<Void>.just(())
        }
        
        return mapTransactionToSingle { (db) in
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
        
        return mapTransactionToSingle { (db) in
            try db.insertOrReplace(objects: messages, intoTable: messageBodyTableName)
        }
    }
    
    func queryMessageBody(objType: String, objId: String) -> Single<Entity.NoticeMessage?> {
        return mapTransactionToSingle { (db) in
            let ex = Entity.NoticeMessage.Properties.objType == objType && Entity.NoticeMessage.Properties.objId == objId
            return try db.getObject(fromTable: messageBodyTableName,
                                    where: ex)
        }
    }
    
    func updateMessageBody(_ message: Entity.NoticeMessage) -> Single<Void> {
        return mapTransactionToSingle { (db) in
            guard let objId = message.objId, let objType = message.objType else {
                return
            }
            let ex = Entity.NoticeMessage.Properties.objType == objType && Entity.NoticeMessage.Properties.objId == objId
            try db.update(table: messageBodyTableName, on: Entity.NoticeMessage.Properties.all, with: message, where: ex)
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
        
        return mapTransactionToSingle { (db) in
            try db.getObjects(fromTable: noticeTableName,
                              orderBy: [Entity.Notice.Properties.ms.asOrder(by: .descending)],
                              limit: limit,
                              offset: offset)
        }
        
    }
    
    func latestNotice() -> Single<Entity.Notice?> {
        return mapTransactionToSingle { (db) in
            try db.getObject(fromTable: noticeTableName,
                             orderBy: [Entity.Notice.Properties.ms.asOrder(by: .descending)])
        }
    }
    
    private func mapTransactionToSingle<T>(_ transaction: @escaping ((Database) throws -> T) ) -> Single<T> {
        
        return Single<T>.create { [weak self] (subscriber) -> Disposable in
            
            guard let `self` = self,
                  let db = self.database else { return Disposables.create() }
            
            self.dbIOQueue.async {
                
                do {
                    let data = try transaction(db)
                    subscriber(.success(data))
                } catch let err {
                    cdPrint("db error: \(err.localizedDescription)")
                    subscriber(.error(err))
                }
            }
            
            return Disposables.create()
        }
        .observeOn(MainScheduler.asyncInstance)
        
    }
    
}
