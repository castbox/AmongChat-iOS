//
//  Request.AmongChatBackend.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import RxSwift

extension Request {
    static let amongchatProvider = MoyaProvider<APIService.AmongChatBackend>(plugins: [
        NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(formatter: NetworkLoggerPlugin.Configuration.Formatter(), output: NetworkLoggerPlugin.Configuration.defaultOutput, logOptions: .verbose)),
        NetworkCachePolicyPlugin(),
        ResponseInterceptPlugin()
    ])
}

struct MsgError: Error, Codable {
    //通用错误码
    enum CodeType: Int {
        case notRoomHost = 3000 //'Only the room host can operate'
        case roomSeatsFull = 3001 //'The room is full'
        case roomUserKick = 3002 //'You are kicked off, can not enter this room'
        case roomNotFound = 202 //'can not find this room'
    }

    static let `default` = MsgError(code: 202, msg: "Please try again.")
    
    let code: Int
    let msg: String?
    
    //
    var codeType: CodeType? {
        return CodeType(rawValue: code)
    }
    
    static func from(dic: [String: Any]) -> MsgError {
        var item: MsgError?
        decoderCatcher {
            item = try JSONDecoder().decodeAnyData(MsgError.self, from: dic)
        }
        return item ?? .default
    }
}

extension Request {
}

extension MsgError: LocalizedError {
    var errorDescription: String? {
        return msg
    }
}

extension Request {
    
    static func login(via provider: Entity.LoginProvider, token: String? = nil, secret: String? = nil, transferFrom uid: String? = nil, clientType: String = "ios") -> Single<Entity.LoginResult?> {
        
        var paras = [String : Any]()
        paras["provider"] = provider.rawValue
        paras["client_type"] = clientType
        paras["box_token"] = 1
        
        if let token = token { paras["token"] = token }
        if let secret = secret { paras["secret"] = secret }
        if let uid = uid { paras["uid"] = uid }
        
        return amongchatProvider.rx.request(.login(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.LoginResult.self)
    }
    
    static func profile() -> Single<Entity.UserProfile?> {
        return amongchatProvider.rx.request(.profile)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.UserProfile.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateProfile(_ profileData: [String : Any]) -> Single<Entity.UserProfile?> {
        let params = ["profile_data" : profileData]
        return amongchatProvider.rx.request(.updateProfile(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.UserProfile.self)
            .observeOn(MainScheduler.asyncInstance)
            .do { _ in
                Settings.shared.updateProfile()
            }
    }
    
    static func summary(country: String? = nil, language: String? = nil) -> Single<Entity.Summary?> {
        
        var paras = [String : Any]()
        
        if let country = country { paras["country"] = country }
        if let language = language { paras["language"] = language }
        
        return amongchatProvider.rx.request(.summary(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.Summary.self)
            .do(onSuccess: { (summary) in
                guard let s = summary else { return }
                Settings.shared.amongChatHomeSummary.value = s
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func enterRoom(roomId: String? = nil, topicId: String?) -> Single<Entity.Room?> {
        
        var paras = [String : Any]()
        if let rid = roomId { paras["room_id"] = rid }
        paras["topic_id"] = topicId
        
        return amongchatProvider.rx.request(.enteryRoom(paras))
            .mapJSON()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                if let data = json["data"] as? [String: AnyObject],
                      let roomData = data["room"] as? [String : AnyObject] {
                    return roomData
                } else {
                    throw MsgError.from(dic: json)
                }
            }
            .mapTo(Entity.Room.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func createRoom(_ room: Entity.RoomProto) -> Single<Entity.Room?> {
        
        guard let params = room.dictionary else {
            return Observable.just(nil).asSingle()
        }
        
        return amongchatProvider.rx.request(.createRoom(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { item -> [String : AnyObject] in
                guard let roomData = item["room"] as? [String : AnyObject] else {
                    return [:]
                }
                return roomData
            }
            .mapTo(Entity.Room.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateRoomInfo(room: Entity.Room?) -> Single<Bool> {
        guard var params = room?.dictionary else {
            return Observable<Bool>.empty().asSingle()
        }
        //
        params.removeValue(forKey: "roomUserList")
        return amongchatProvider.rx.request(.updateRoomInfo(params))
            .mapJSON()
            .map { (jsonAny) -> Bool in
                guard let jsonDict = jsonAny as? [String : Any],
                      let processed = jsonDict["processed"] as? Bool else { return false }
                return processed
            }
    }
    
    static func updateRoom(nickName: String, with roomId: String) -> Single<Bool> {
        return amongchatProvider.rx.request(.roomNickName(["nickname": nickName, "room_id": roomId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func requestRoomInfo(with roomId: String) -> Single<Entity.Room?> {
        return amongchatProvider.rx.request(.roomInfo(["room_id": roomId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { item -> [String : AnyObject] in
                guard let roomData = item["room"] as? [String : AnyObject] else {
                    return [:]
                }
                return roomData
            }
            .mapTo(Entity.Room.self)
    }
    static func requestLeave(with roomId: String) -> Single<Bool> {
        return amongchatProvider.rx.request(.leaveRoom(["room_id": roomId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
    }
    
    static func logout() -> Single<[String: AnyObject]> {
        return amongchatProvider.rx.request(.logout)
            .mapJSON().mapToDataJson()
    }
    
    static func defaultAvatars(withLocked: Int? = nil) -> Single<Entity.DefaultAvatars?> {
        
        var params = [String : Any]()
        
        if let l = withLocked {
            params["with_locked"] = l
        }
        
        return amongchatProvider.rx.request(.defaultAvatars(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.DefaultAvatars.self)
            .do(onSuccess: { (defaultAvatars) in
                guard let d = defaultAvatars else { return }
                Settings.shared.amongChatDefaultAvatars.value = d
            })
    }
    
    static func unlockAvatar(_ avatar: Entity.DefaultAvatar) -> Single<Bool> {
        
        var params = [String : Any]()
        
        params["avatar_id"] = avatar.avatarId
        
        return amongchatProvider.rx.request(.unlockAvatar(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (json) -> Bool in
                
                guard let data = json["data"] as? [String : AnyObject],
                      let process = data["process"] as? Bool,
                      process else {
                    return false
                }
                
                return true
            }
        
    }
    
    static func requestFirebaseToken(_ uid: Int) -> Single<String> {
        let paras = ["uid": uid]
        return amongchatProvider.rx.request(.firebaseToken(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { values -> String in
                guard let token = values["firebase_custom_token"] as? String else {
                    throw MsgError.default
                }
                return token
            }
        
    }
    
    static func devices(fcmToken: String) -> Single<Bool>{
        return amongchatProvider.rx.request(.updateDevice(["token": fcmToken, "push_type": "fcm"]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
    }
    
    static func seneitiveWords() -> Single<[String]> {
        return amongchatProvider.rx.request(.sensitiveWords)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { values -> [String] in
                guard let token = values["datas"] as? [String] else {
                    throw MsgError.default
                }
                return token
            }
    }
}
