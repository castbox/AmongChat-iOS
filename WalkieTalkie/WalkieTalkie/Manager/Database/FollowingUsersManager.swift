//
//  FollowingUsersManager.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/22.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import WCDBSwift
import RxSwift
import RxCocoa

private let usersTableName = Database.TableName.followingUsers.rawValue

class FollowingUsersManager {
    
    static let shared = FollowingUsersManager()
    
    private let database = Database.shared
    
    private let tableUpdatedSignal = PublishSubject<Void>()
    
    func addUsers(_ userList: [Entity.UserProfile]) -> Single<Void> {
        
        guard userList.count > 0 else {
            return Single<Void>.just(())
        }
        
        return database.mapTransactionToSingle { (db) in
            try db.insertOrReplace(objects: userList, intoTable: usersTableName)
        }
        .do(onSuccess: { [weak self] _ in
            self?.tableUpdatedSignal.onNext(())
        })
    }
    
    func userList(limit: Int? = nil, offset: Int? = nil) -> Single<[Entity.UserProfile]> {
        
        return database.mapTransactionToSingle { (db) in
            try db.getObjects(fromTable: usersTableName,
                              orderBy: [Entity.UserProfile.Properties.opTime.asOrder(by: .descending)],
                              limit: limit,
                              offset: offset)
        }
        
    }
    
    func allUsersObservable() -> Observable<[Entity.UserProfile]> {
        
        return tableUpdatedSignal.startWith(())
            .flatMap { [weak self] _ -> Observable<[Entity.UserProfile]> in
                guard let `self` = self else {
                    return Observable.just([])
                }
                
                return self.userList().asObservable()
            }
        
    }
    
    func removeUser(_ uid: Int) -> Single<Void> {
        return database.mapTransactionToSingle { db in
            try db.delete(fromTable: usersTableName,
                          where: Entity.UserProfile.Properties.uid == uid,
                          orderBy: nil,
                          limit: nil,
                          offset: nil)
        }
        .do(onSuccess: { [weak self] _ in
            self?.tableUpdatedSignal.onNext(())
        })
        
    }
    
    func updateUser(_ user: Entity.UserProfile) -> Single<Void> {
        
        return database.mapTransactionToSingle { (db) in
            try db.update(table: usersTableName, with: user, where: Entity.UserProfile.Properties.uid == user.uid)
        }
        .do(onSuccess: { [weak self] _ in
            self?.tableUpdatedSignal.onNext(())
        })
    }
    
    func oldestUser() -> Single<Entity.UserProfile?> {
        return database.mapTransactionToSingle { (db) in
            try db.getObject(fromTable: usersTableName,
                             orderBy: [Entity.UserProfile.Properties.opTime.asOrder(by: .ascending)])
        }
    }
    
}
