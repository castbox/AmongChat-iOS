//
//  FireStore.FriendsModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/26.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension FireStore {
    struct Entity { }
}

extension FireStore.Entity {
    struct User {
        var blockList: [String]
        var muteList: [String]
        var profile: Profile
        var status: Status
        
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
    
    init?(with dict: [String : Any]) {
        
        guard let profileDict = dict[Keys.profile] as? [String : Any],
            let statusDict = dict[Keys.status] as? [String : Any] else { return nil }
        
        guard let profile = Profile(with: profileDict) else { return nil}
        
        self.profile = profile
        status = Status(with: statusDict)
        
        blockList = dict[Keys.blockList] as? [String] ?? []
        muteList = dict[Keys.muteList] as? [String] ?? []
    }
    
}

extension FireStore.Entity.User {
    struct Profile {
        var avatar: String
        var birthday: String
        var name: String
        var premium: Bool
        let uidInt: Int
        var updatedAt: Timestamp
        
        struct Keys {
            static let avatar = "avatar"
            static let birthday = "birthday"
            static let name = "name"
            static let premium = "premium"
            static let uidInt = "uidInt"
            static let updatedAt = "updatedAt"
        }
    }
}

extension FireStore.Entity.User.Profile {
    
    init?(with dict: [String : Any]) {
        guard let uid = dict[Keys.uidInt] as? Int else { return nil }
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

}

extension FireStore.Entity.User {
    struct Status {
        var currentChannel: String
        var heartbeatAt: Timestamp
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
        let docId: String
        
        struct Keys {
            static let msgType = "msgType"
            static let uid = "uid"
            static let channel = "channel"
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

    }
    
    func toDictionary() -> [String : Any] {
        
        var dict = [
            Keys.msgType : msgType.rawValue,
            Keys.uid : uid
        ]
        
        if let channel = channel {
            dict[Keys.channel] = channel
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
