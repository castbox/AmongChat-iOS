//
//  FireStore.FriendsModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/26.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import FirebaseFirestore
import RxSwift

extension FireStore {
    struct Entity { }
}

extension FireStore.Entity {
    struct User {
        var blockList: [String]
        var muteList: [UInt]
        var profile: Profile
        var status: Status
        let uid: String
        
        struct Keys {
            static let blockList = "blockList"
            static let muteList = "muteList"
            static let profile = "profile"
            static let status = "status"
        }
        
        struct Collection {
            static let channelInvitationMsgs = "channelInvitationMsgs"
            static let commonMsgs = "commonMsgs"
            static let followers = "followers"
            static let following = "following"
        }

    }
}

extension FireStore.Entity.User {
    
    init?(with dict: [String : Any], uid: String) {
        
        guard let profileDict = dict[Keys.profile] as? [String : Any],
            let statusDict = dict[Keys.status] as? [String : Any] else { return nil }
        
        guard let profile = Profile(with: profileDict) else { return nil}
        
        self.profile = profile
        status = Status(with: statusDict)
        
        blockList = dict[Keys.blockList] as? [String] ?? []
        muteList = dict[Keys.muteList] as? [UInt] ?? []
        self.uid = uid
    }
    
}

extension FireStore.Entity.User {
    struct Profile {
        var avatar: String
        var birthday: String
        var name: String
        var premium: Bool
        let uidInt: UInt
        var updatedAt: Timestamp = Timestamp(date: Date())
        
        struct Keys {
            static let avatar = "avatar"
            static let birthday = "birthday"
            static let name = "name"
            static let premium = "premium"
            static let uidInt = "uidInt"
            static let updatedAt = "updatedAt"
            static let uid = "uid"
        }
    }
}

extension FireStore.Entity.User.Profile {
    
    init?(with dict: [String : Any]) {
        guard let uid = dict[Keys.uidInt] as? UInt else { return nil }
        uidInt = uid
        avatar = dict[Keys.avatar] as? String ?? ""
        birthday = dict[Keys.birthday] as? String ?? ""
        name = dict[Keys.name] as? String ?? ""
        premium = dict[Keys.premium] as? Bool ?? false
        updatedAt = dict[Keys.updatedAt] as? Timestamp ?? Timestamp(date: Date())
    }
    
    func toDictionary() -> [String : Any] {
        return [
            Keys.avatar : avatar,
            Keys.birthday : birthday,
            Keys.name : name,
            Keys.premium : premium,
            Keys.uidInt : uidInt,
            Keys.updatedAt : FieldValue.serverTimestamp()
        ]
    }
    
    static func randomDefaultAvatar() -> (UIImage?, Int) {
        let idx = Int.random(in: 0...4)
        let image = UIImage(named: "default_avatar_\(idx)")
        return (image, idx)
    }
    
    var avatarObservable: Single<UIImage?> {
        return Observable<UIImage?>.create { (subscriber) -> Disposable in
            
            if self.avatar.starts(with: "http") {
                // TODO: avatar fetching
            } else if let idx = Int(self.avatar){
                let image = UIImage(named: "default_avatar_\(idx)")
                subscriber.onNext(image)
                subscriber.onCompleted()
            } else {
                subscriber.onNext(nil)
                subscriber.onCompleted()
            }
            
            return Disposables.create { }
        }
        .asSingle()
    }
}

extension FireStore.Entity.User {
    struct Status {
        var currentChannel: String
        var heartbeatAt: Timestamp = Timestamp(date: Date())
        var online: Bool
        
        struct Keys {
            static let currentChannel = "currentChannel"
            static let heartbeatAt = "heartbeatAt"
            static let online = "online"
        }
    }
}

extension FireStore.Entity.User.Status {
    
    init(with dict: [String : Any]) {
        currentChannel = dict[Keys.currentChannel] as? String ?? ""
        heartbeatAt = dict[Keys.heartbeatAt] as? Timestamp ?? Timestamp(date: Date())
        online = dict[Keys.online] as? Bool ?? true
    }
    
    func toDictionary() -> [String : Any] {
        return [
            Keys.currentChannel : currentChannel,
            Keys.heartbeatAt : FieldValue.serverTimestamp(),
            Keys.online : online
        ]
    }
    
}

extension FireStore.Entity.User {
    
    struct FriendMeta {
        let createdAt: Timestamp
        let uid: String
        let docId: String
        
        struct Keys {
            static let createdAt = "createdAt"
        }
        
    }
    
    struct CommonMessage {
        let msgType: MessageType
        let uid: String
        let channel: String?
        let username: String?
        let avatar: String?
        let docId: String
        
        struct Keys {
            static let msgType = "msgType"
            static let uid = "uid"
            static let channel = "channel"
            static let username = "username"
            static let avatar = "avatar"
        }
        
        enum MessageType: String {
            case enterRoom
            case channelEntryRequest
            case channelEntryRefuse
            case channelEntryAccept
        }
        
    }
    
    struct ChannelInvitationMessage {
        let channel: String
        let createdAt: Timestamp
        let uid: String
        let docId: String
        
        struct Keys {
            static let channel = "channel"
            static let createdAt = "createdAt"
            static let uid = "uid"
            static let docId = "docId"
        }
        
    }
    
}

extension FireStore.Entity.User.FriendMeta {
    
    init?(with doc: QueryDocumentSnapshot) {
        let dict = doc.data()
        
        guard let ts = dict[Keys.createdAt] as? Timestamp else {
            return nil
        }
        
        createdAt = ts
        uid = doc.documentID
        docId = doc.documentID
    }
    
}

extension FireStore.Entity.User.ChannelInvitationMessage {
    
    init?(with doc: QueryDocumentSnapshot) {
        let dict = doc.data()
        
        guard let ch = dict[Keys.channel] as? String,
            let uid = dict[Keys.uid] as? String,
            let ts = dict[Keys.createdAt] as? Timestamp else {
            return nil
        }
        
        channel = ch
        self.uid = uid
        createdAt = ts
        docId = doc.documentID
    }
    
    func toDictionary() -> [String : Any] {
        return [
            Keys.channel : channel,
            Keys.createdAt : FieldValue.serverTimestamp(),
            Keys.uid : uid
        ]
    }
}

extension FireStore.Entity.User.CommonMessage {
    
    init?(with doc: QueryDocumentSnapshot) {
        let dict = doc.data()
        
        guard let type = dict[Keys.msgType] as? String,
            let msgType = MessageType(rawValue: type),
            let from = dict[Keys.uid] as? String else { return nil }
        
        self.msgType = msgType
        uid = from
        channel = dict[Keys.channel] as? String
        docId = doc.documentID
        username = dict[Keys.username] as? String
        avatar = dict[Keys.avatar] as? String

    }
    
    func toDictionary() -> [String : Any] {
        
        var dict = [
            Keys.msgType : msgType.rawValue,
            Keys.uid : uid
        ]
        
        if let channel = channel {
            dict[Keys.channel] = channel
        }
        
        if let username = username {
            dict[Keys.username] = username
        }
        
        if let avatar = avatar {
            dict[Keys.avatar] = avatar
        }
        
        return dict
    }

}

extension FireStore.Entity {
    struct UserMeta {
        let uid: String
        
        struct Keys {
            static let uid = "uid"
        }
        
    }
}

extension FireStore.Entity.UserMeta {
    
    init?(with dict: [String : Any]) {
        guard let uid = dict[Keys.uid] as? String else { return nil }
        self.uid = uid
    }
    
    func toDictionary() -> [String : Any] {
        return [
            Keys.uid : uid
        ]
    }
    
}
