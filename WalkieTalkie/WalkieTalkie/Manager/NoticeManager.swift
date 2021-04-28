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
    
    private let dbURL: URL = {
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask,
                                                         true).last! + "/Notice/Notice.db"
        return URL(fileURLWithPath: dbPath)
    }()
    
    
    private let database: Database
    
    private init() {
        
        database = Database(withFileURL: dbURL)
        database.setTokenizes([.WCDB])
        
        do {
            try database.create(table: noticeTableName, of: Entity.Notice.self)
            try database.create(table: messageBodyTableName, of: Entity.NoticeMessage.self)
        } catch let error {
            cdPrint("create table error \(error.localizedDescription)")
        }
        
    }
    
    func addNoticeList(_ noticeList: [Entity.Notice]) -> Single<Void> {
        
        return mapTransactionToSingle { (db) in
            try db.insertOrReplace(objects: noticeList, intoTable: noticeTableName)
        }
        
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
            
            guard let `self` = self else { return Disposables.create() }
            
            self.dbIOQueue.async {
                
                do {
                    let data = try transaction(self.database)
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
