//
//  Database.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 08/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import WCDBSwift
import RxSwift
import RxCocoa

private let noticeTableName = "notices"
private let messageBodyTableName = "messges"
private let dmConversationTableName = "dm_conversation"
private let dmMessageTableName = "dm_messages"


class Database {
    
    enum TableName: String, CaseIterable {
        case notice = "notices"
        case messageBody = "messges"
        case dmConversation = "dm_conversation"
        case dmMessages = "dm_messages"
    }
    
    
    static let shared = Database()
    
    private let dbIOQueue = DispatchQueue.init(label: "among.chat.notice.db.io", qos: .userInitiated)
        
    private var database: WCDBSwift.Database? = nil {
        didSet {
            oldValue?.close()
        }
    }
    
    private init() {
        
        let _ = Settings.shared.loginResult.replay()
            .filterNil()
            .subscribe(onNext: { [weak self] (loginUser) in
                
                guard let `self` = self else { return }
                                
                let database = WCDBSwift.Database(withFileURL: self.dbURL(of: loginUser.uid))
                database.setTokenizes([.WCDB])
                
                do {
                    try database.create(table: .notice, of: Entity.Notice.self)
                    try database.create(table: .messageBody, of: Entity.NoticeMessage.self)
                    try database.create(table: .dmConversation, of: Entity.DMConversation.self)
                    try database.create(table: .dmMessages, of: Entity.DMMessage.self)
                    self.database = database
                } catch let error {
                    cdPrint("create table error \(error.localizedDescription)")
                }
                
            })
    }
    
    func mapTransactionToSingle<T>(_ transaction: @escaping ((WCDBSwift.Database) throws -> T)) -> Single<T> {
        
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
    
    func close() {
        
    }
    
    private func dbURL(of user: Int) -> URL {
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask,
                                                         true).last! + "/Notice/\(user)/Notice.db"
        return URL(fileURLWithPath: dbPath)
    }
}

extension Database.TableName {

}

extension WCDBSwift.Database {
    func create<Root: TableDecodable>(table name: Database.TableName, of rootType: Root.Type) throws {
        try create(table: name.rawValue, of: rootType)
    }
}
