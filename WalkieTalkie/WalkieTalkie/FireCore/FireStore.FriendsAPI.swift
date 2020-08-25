//
//  FireStore.FriendsAPI.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseCore
import RxSwift
import RxCocoa
import SwifterSwift


extension FireStore {
    
    // MARK: - handle collections under user document
    
    func fetchFollowingList(of user: String) -> Single<[Entity.User]> {
        
        typealias User = Entity.User
        
        return Observable<[User]>.create({ [weak self] (observer) -> Disposable in
                self?.db.collection(Root.users)
                .document(user)
                .collection(User.Collection.following)
                .getDocuments(completion: { (query, error) in
                    
                    guard error == nil else {
                        observer.onError(error!)
                        return
                    }
                    
                    guard let query = query else {
                        observer.onNext([])
                        observer.onCompleted()
                        return
                    }
                    
                    let uidList = query.documents.map { $0.documentID }
                    
                    self?.db.collection(Root.users)
                        .whereField(FieldPath.documentID(), in: uidList)
                        .getDocuments(completion: { (query, error) in
                            guard error == nil else {
                                observer.onError(error!)
                                return
                            }
                            
                            guard let query = query else {
                                observer.onNext([])
                                observer.onCompleted()
                                return
                            }
                            
                            let followingUsers = query.documents.compactMap { User(with: $0.data()) }
                            
                            observer.onNext(followingUsers)
                            observer.onCompleted()
                        })
                    
                })
            return Disposables.create { }
        })
        .asSingle()
    }
    
    func fetchFollowerList(of user: String) -> Single<[Entity.User]> {

        typealias User = Entity.User
        
        return Observable<[User]>.create({ [weak self] (observer) -> Disposable in
            self?.db.collection(Root.users)
                .document(user)
                .collection(User.Collection.followers)
                .getDocuments(completion: { (query, error) in
                    guard error == nil else {
                        observer.onError(error!)
                        return
                    }
                    
                    guard let query = query else {
                        observer.onNext([])
                        return
                    }
                    let uidList = query.documents.map { $0.documentID }
                    
                    self?.db.collection(Root.users)
                        .whereField(FieldPath.documentID(), in: uidList)
                        .getDocuments(completion: { (query, error) in
                            
                            guard error == nil else {
                                observer.onError(error!)
                                return
                            }
                            
                            guard let query = query else {
                                observer.onNext([])
                                observer.onCompleted()
                                return
                            }
                            
                            let followerUsers = query.documents.compactMap { User(with: $0.data()) }
                            
                            observer.onNext(followerUsers)
                            observer.onCompleted()
                        })
                })
            
            return Disposables.create { }
        })
        .asSingle()
    }
    
    func addFollowing(_ followingUser: String, to user: String) {
        db.collection(Root.users)
            .document(user)
            .collection(Entity.User.Collection.following)
            .document(followingUser)
            .setData([
                Entity.User.FriendMeta.Keys.createdAt : FieldValue.serverTimestamp()
            ])
    }
    
    func removeFollowing(_ followingUser: String, from user: String) {
        db.collection(Root.users)
            .document(user)
            .collection(Entity.User.Collection.following)
            .document(followingUser)
            .delete()
    }
    
    func newFollowerObservable(of user: String) -> Observable<Entity.User.FriendMeta> {
        
        return Observable<Entity.User.FriendMeta>.create { [weak self] (subscriber) -> Disposable in
            
            let ref = self?.db.collection(Root.users)
                .document(user)
                .collection(Entity.User.Collection.followers)
                .addSnapshotListener { (query, error) in
                    
                    guard error == nil else {
                        subscriber.onError(error!)
                        return
                    }
                    
                    guard let query = query else {
                        subscriber.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                        return
                    }
                    
                    query.documentChanges.forEach { (diff) in
                        switch diff.type {
                        case .added:
                            if let followerMeta = Entity.User.FriendMeta(with: diff.document) {
                                subscriber.onNext(followerMeta)
                            }
                        default:
                            ()
                        }
                    }
            }
            
            return Disposables.create {
                ref?.remove()
            }
            
        }
        
    }
    
    func followingObservable(of user: String) -> Observable<[Entity.User.FriendMeta]> {
        
        return Observable<[Entity.User.FriendMeta]>.create { [weak self] (subscriber) -> Disposable in
            
            let ref = self?.db.collection(Root.users)
                .document(user)
                .collection(Entity.User.Collection.following)
                .addSnapshotListener({ (query, error) in
                    guard error == nil else {
                        subscriber.onError(error!)
                        return
                    }
                    
                    guard let query = query else {
                        subscriber.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                        return
                    }
                    
                    let list = query.documents.compactMap { Entity.User.FriendMeta(with: $0) }
                    subscriber.onNext(list)
                })
            
            return Disposables.create {
                ref?.remove()
            }
            
        }
    }
    
    func followersObservable(of user: String) -> Observable<[Entity.User.FriendMeta]> {
        
        return Observable<[Entity.User.FriendMeta]>.create { [weak self] (subscriber) -> Disposable in
            
            let ref = self?.db.collection(Root.users)
                .document(user)
                .collection(Entity.User.Collection.followers)
                .addSnapshotListener({ (query, error) in
                    guard error == nil else {
                        subscriber.onError(error!)
                        return
                    }
                    
                    guard let query = query else {
                        subscriber.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                        return
                    }
                    
                    let list = query.documents.compactMap { Entity.User.FriendMeta(with: $0) }
                    subscriber.onNext(list)
                })
            
            return Disposables.create {
                ref?.remove()
            }
            
        }
        
    }
    
    func newChannelInvitationMsgObservable(of user: String) -> Observable<Entity.User.ChannelInvitationMessage> {
        
        typealias User = Entity.User
        
        return Observable<User.ChannelInvitationMessage>.create({ [weak self] (observer) -> Disposable in
            let ref = self?.db.collection(Root.users)
                .document(user)
                .collection(User.Collection.channelInvitationMsgs)
                .addSnapshotListener(includeMetadataChanges: true, listener: { (query, error) in
                    
                    guard error == nil else {
                        observer.onError(error!)
                        return
                    }
                    
                    guard let query = query else {
                        observer.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                        return
                    }
                    
                    query.documentChanges.forEach { (diff) in
                        switch diff.type {
                        case .added:
                            if let msg = User.ChannelInvitationMessage(with: diff.document) {
                                observer.onNext(msg)
                            }
                        default:
                            ()
                        }
                    }
                })
            
            return Disposables.create {
                ref?.remove()
            }
        })
    }
    
    func newCommonMsgObservable(of user: String) -> Observable<Entity.User.CommonMessage> {
        
        typealias User = Entity.User
        
        return Observable<User.CommonMessage>.create({ [weak self] (observer) -> Disposable in
            let ref = self?.db.collection(Root.users)
                .document(user)
                .collection(User.Collection.commonMsgs)
                .addSnapshotListener(includeMetadataChanges: true, listener: { (query, error) in
                    
                    guard error == nil else {
                        observer.onError(error!)
                        return
                    }
                    
                    guard let query = query else {
                        observer.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                        return
                    }
                    
                    query.documentChanges.forEach { (diff) in
                        switch diff.type {
                        case .added:
                            if let msg = User.CommonMessage(with: diff.document) {
                                observer.onNext(msg)
                            }
                        default:
                            ()
                        }
                    }
                })
            
            return Disposables.create {
                ref?.remove()
            }
        })
    }
    
    func flushCommonMsg(of user: String) {
        typealias User = Entity.User
        
        let batch = db.batch()
        
        db.collection(Root.users)
            .document(user)
            .collection(User.Collection.commonMsgs)
            .getDocuments { (snapshot, err) in
                guard err == nil,
                    let query = snapshot else {
                        return
                }
                query.documents
                    .forEach { (doc) in
                        batch.deleteDocument(doc.reference)
                }
        }
        
        batch.commit()
    }
    
    func deleteChannelInvitationMsg(_ msg: Entity.User.ChannelInvitationMessage, of user: String) {
        db.collection(Root.users)
            .document(user)
            .collection(Entity.User.Collection.channelInvitationMsgs)
            .document(msg.docId)
            .delete { (err) in
                if let err = err {
                    NSLog("Error removing document: \(err)")
                } else {
                    NSLog("Document successfully removed!")
                }
        }
    }
    
    private func addCommonMsg(_ msg: Entity.User.CommonMessage, to user: String) {
        db.collection(Root.users)
            .document(user)
            .collection(Entity.User.Collection.commonMsgs)
            .addDocument(data: msg.toDictionary())
    }
    
    private func addChannelInvitationMsg(_ msg: Entity.User.ChannelInvitationMessage, to user: String) {
        db.collection(Root.users)
            .document(user)
            .collection(Entity.User.Collection.channelInvitationMsgs)
            .addDocument(data: msg.toDictionary())
    }
    
    func acceptChannelInvitation(_ invitationMsg: Entity.User.ChannelInvitationMessage, to invitee: String) {
        let acceptMsg = Entity.User.CommonMessage(msgType: .enterRoom, uid: invitee, channel: nil, docId: "")
        addCommonMsg(acceptMsg, to: invitationMsg.uid)
    }
    
    func sendJoinChannelRequest(from requester: String, to user: String, toJoin channel: String) {
        let requestJoinMsg = Entity.User.CommonMessage(msgType: .channelEntryRequest, uid: requester, channel: nil, docId: "")
        addCommonMsg(requestJoinMsg, to: user)
    }
    
    func refuseJoinChannelRequest(_ msg: Entity.User.CommonMessage, by user: String) {
        let refuseJoinMsg = Entity.User.CommonMessage(msgType: .channelEntryRefuse, uid: user, channel: nil, docId: "")
        addCommonMsg(refuseJoinMsg, to: msg.uid)
    }
    
    func acceptJoinChannelRequest(_ msg: Entity.User.CommonMessage, toJoinChannel: String, by user: String) {
        let acceptJoinMsg = Entity.User.CommonMessage(msgType: .channelEntryAccept, uid: user, channel: toJoinChannel, docId: "")
        addCommonMsg(acceptJoinMsg, to: msg.uid)
    }
    
    func sendChannelInvitation(to invitee: String, toJoin channel: String, from inviter: String) {
        let invitationMsg = Entity.User.ChannelInvitationMessage(channel: channel, createdAt: Timestamp(date: Date()), uid: inviter, docId: "")
        addChannelInvitationMsg(invitationMsg, to: invitee)
    }
    
}

extension FireStore {
    
    // MARK: - handle fields under user document
    
    func userObservable(_ user: String) -> Observable<Entity.User> {
        
        return Observable<Entity.User>.create { [weak self] (subscriber) -> Disposable in
            
            guard let `self` = self else {
                subscriber.onError(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey : ""]))
                return Disposables.create { }
            }
            
            let listener = self.db.collection(Root.users)
                .document(user)
                .addSnapshotListener({ (doc, error) in
                    
                    guard error == nil else {
                        subscriber.onError(error!)
                        return
                    }
                    
                    guard let doc = doc else {
                        subscriber.onError(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey : ""]))
                        return
                    }
                    
                    guard let dict = doc.data() else {
                        // document 不存在
                        subscriber.onError(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey : ""]))
                        return
                    }
                    
                    guard let user = Entity.User(with: dict) else {
                        // document field字段不匹配
                        subscriber.onError(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey : ""]))
                        return
                    }
                    
                    subscriber.onNext(user)
                })
            
            return Disposables.create {
                listener.remove()
            }
        }
        
    }
    
    func updateStatus(_ status: Entity.User.Status, of user: String) {
        db.collection(Root.users)
            .document(user)
            .updateData([
                Entity.User.Keys.status : status.toDictionary()
            ])
    }
    
    func addBlockUser(_ blockUser: String, to user: String) {
        db.collection(Root.users)
            .document(user)
            .updateData([
                Entity.User.Keys.blockList : FirebaseFirestore.FieldValue.arrayUnion([blockUser])
            ])
    }
    
    func removeBlockUser(_ blockUser: String, from user: String) {
        db.collection(Root.users)
            .document(user)
            .updateData([
                Entity.User.Keys.blockList : FirebaseFirestore.FieldValue.arrayRemove([blockUser])
            ])
    }
    
    func addMuteUser(_ muteUser: String, to user: String) {
        db.collection(Root.users)
            .document(user)
            .updateData([
                Entity.User.Keys.muteList : FirebaseFirestore.FieldValue.arrayUnion([muteUser])
            ])
    }
    
    func removeMuteUser(_ muteUser: String, from user: String) {
        db.collection(Root.users)
            .document(user)
            .updateData([
                Entity.User.Keys.muteList : FirebaseFirestore.FieldValue.arrayRemove([muteUser])
            ])
    }
    
    func updateProfile(_ profile: Entity.User.Profile, of user: String) {
        db.collection(Root.users)
            .document(user)
            .updateData([
                Entity.User.Keys.profile : profile.toDictionary()
            ])
    }
    
}

extension FireStore {
    
    // MARK: - handle user-meta document
    
    func addUserMeta(with uidInt: Int, and uidString: String) {
        
        let userMeta = Entity.UserMeta(uid: uidString)
        
        db.collection(Root.userMeta)
        .document("\(uidInt)")
        .setData(userMeta.toDictionary())
    }
    
    func fetchUserMeta(_ uidInt: Int) -> Single<Entity.UserMeta?> {
        return Observable<Entity.UserMeta?>.create { [weak self] (subscriber) -> Disposable in
            
            self?.db.collection(Root.userMeta)
                .document("\(uidInt)")
                .getDocument(completion: { (doc, error) in
                    
                    guard error == nil else {
                        subscriber.onError(error!)
                        return
                    }
                    
                    guard let doc = doc,
                        let dict = doc.data(),
                        let userMeta = Entity.UserMeta(with: dict) else {
                        subscriber.onNext(nil)
                        subscriber.onCompleted()
                        return
                    }
                    
                    subscriber.onNext(userMeta)
                    subscriber.onCompleted()
                    
                })
            
            return Disposables.create {
                
            }
        }
        .asSingle()
    }
    
}
