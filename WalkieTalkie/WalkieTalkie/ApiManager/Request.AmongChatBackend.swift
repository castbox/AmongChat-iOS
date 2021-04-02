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
import SwiftyUserDefaults

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
        case notEnoughRoomCard = 3004 // no free room card for create
        case needUpgrade = 3005 //need upgrade app
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

extension Error {
    var msgOfError: String? {
        if let msgErr = self as? MsgError {
            return msgErr.msg
        } else {
            return (self as NSError).localizedDescription
        }
    }
}

extension Request {
}

extension MsgError: LocalizedError {
    var errorDescription: String? {
        return msg
    }
}

private let limit: Int = 20

extension Request {
    
    static func login(via provider: Entity.LoginResult.Provider, token: String? = nil, secret: String? = nil, transferFrom uid: String? = nil, clientType: String = "ios") -> Single<Entity.LoginResult?> {
        
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
            .observeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { (result) in
                guard let result = result else { return }
                Settings.shared.loginResult.value = result
            })
    }
    
    static func profile(_ uid: Int? = nil) -> Single<Entity.UserProfile?> {
        let paras = ["uid": uid ?? Settings.loginUserId ?? 0]
        return amongchatProvider.rx.request(.profile(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.UserProfile.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    @available(*, deprecated, message: "use the one parameter type is Entity.ProfileProto instead")
    static func updateProfile(_ profileData: [String : Any]) -> Single<Entity.UserProfile?> {
        let params = ["profile_data" : profileData]
        return amongchatProvider.rx.request(.updateProfile(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.UserProfile.self)
            .do { _ in
                Settings.shared.updateProfile()
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateProfile(_ profile: Entity.ProfileProto) -> Single<Entity.UserProfile?> {
        
        guard let profileData = profile.dictionary else {
            return Single.error(MsgError.default)
        }
        
        let params = ["profile_data" : profileData]
        return amongchatProvider.rx.request(.updateProfile(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.UserProfile.self)
            .do { _ in
                Settings.shared.updateProfile()
            }
            .observeOn(MainScheduler.asyncInstance)
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
    
    static func enterRoom(roomId: String? = nil, topicId: String?, source: String? = nil) -> Single<Entity.Room?> {
        
        var paras = [String : Any]()
        if let rid = roomId { paras["room_id"] = rid }
        paras["topic_id"] = topicId
        if let s = source { paras["source"] = s }
        paras["rtc_support"] = "agora,zego"
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
        
        guard var params = room.dictionary else {
            return Observable.just(nil).asSingle()
        }
        params["rtc_support"] = "agora,zego"

        return amongchatProvider.rx.request(.createRoom(params))
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
    
    static func updateRoomInfo(room: Entity.Room?) -> Single<Entity.Room?> {
        guard var params = room?.dictionary else {
            return Observable<Entity.Room?>.empty().asSingle()
        }
        params.removeValue(forKey: "userList")
        return amongchatProvider.rx.request(.updateRoomInfo(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (jsonAny) -> [String: AnyObject] in
                guard let processed = jsonAny["processed"] as? Bool,
                      processed,
                      let room = jsonAny["room"] as? [String: AnyObject] else {
                    return [:]
                }
                return room
            }
            .mapTo(Entity.Room.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateRoom(topic: AmongChat.Topic, nickName: String, with roomId: String) -> Single<Bool> {
        
        return amongchatProvider.rx.request(.roomNickName(["name_\(topic.rawValue)": nickName, "room_id": roomId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
    }
    
    static func roomInfo(with roomId: String) -> Single<Entity.Room?> {
        return amongchatProvider.rx.request(.roomInfo(["room_id": roomId, "exclude_fields": "bgUrl"]))
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
    static func leave(with roomId: String) -> Single<Bool> {
        return amongchatProvider.rx.request(.leaveRoom(["room_id": roomId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
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
        //default add pro
        params["with_pro"] = 1
        
        return amongchatProvider.rx.request(.defaultAvatars(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.DefaultAvatars.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func unlockAvatar(_ avatar: Entity.DefaultAvatar) -> Single<Bool> {
        
        var params = [String : Any]()
        
        params["avatar_id"] = avatar.avatarId
        
        return amongchatProvider.rx.request(.unlockAvatar(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (json) -> Bool in
                
                guard let process = json["process"] as? Bool,
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
    
    static func kick(_ users: [Int], roomId: String) -> Single<Bool> {
        let params: [String: Any] = [
            "room_id": roomId, "uids": users.map { $0.string }.joined(separator: ",")
        ]
        return Request.amongchatProvider.rx.request(.kickUsers(params))
            .mapJSON()
            .map { $0 != nil }
            .observeOn(MainScheduler.asyncInstance)
    }

    static func profilePage(uid: Int) -> Single<Entity.ProfilePage?> {
        let paras = ["uid": uid]
        return amongchatProvider.rx.request(.profilePage(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.ProfilePage.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    /// type: follow / block
    static func follow(uid: Int, type: String) -> Single<Bool> {
        let paras = ["target_uid": uid, "relation_type": type] as [String : Any]
        return amongchatProvider.rx.request(.follow(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    /// type: follow / block
    static func unFollow(uid: Int, type: String) -> Single<Bool> {
        let paras = ["target_uid": uid, "relation_type": type] as [String : Any]
        return amongchatProvider.rx.request(.unFollow(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func relationData(uid: Int) -> Single<Entity.RelationData?> {
        let paras = ["target_uid": uid]
        return amongchatProvider.rx.request(.relationData(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.RelationData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func blockList(uid: Int, skipMs: Double) -> Single<Entity.FollowData?> {
        
        let paras = ["relation_type": "block", "uid": uid,
                     "limit": limit, "skip_ms": skipMs] as [String : Any]
        return amongchatProvider.rx.request(.blockList(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func followingList(uid: Int, skipMs: Double) -> Single<Entity.FollowData?> {
        
        let paras = ["relation_type": "follow", "uid": uid,
                     "limit": limit, "skip_ms": skipMs] as [String : Any]
        return amongchatProvider.rx.request(.followingList(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func followerList(uid: Int, skipMs: Double) -> Single<Entity.FollowData?> {
        let paras = ["uid": uid, "limit": limit, "skip_ms": skipMs] as [String : Any]
        return amongchatProvider.rx.request(.followerList(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func endUsers(roomId: String) -> Single<Entity.FollowData?> {
        let paras = ["room_id": roomId]
        return amongchatProvider.rx.request(.exitRoomRecommend(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func inviteFriends(skipMs: Double) -> Single<Entity.FollowData?> {
        let paras = ["limit": limit, "skip_ms": skipMs] as [String : Any]
        return amongchatProvider.rx.request(.inviteFriends(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func onlineStrangers() -> Single<Entity.FollowData?> {
        return amongchatProvider.rx.request(.onlineStrangers)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func inviteUser(roomId: String, uid: Int, isStranger: Bool) -> Single<Entity.FollowData?> {
        let paras = ["room_id": roomId, "uid": uid, "is_stranger": isStranger.int] as [String : Any]
        return amongchatProvider.rx.request(.inviteUser(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
        
    static func friendsPlayingList() -> Single<[Entity.PlayingUser]> {
        return amongchatProvider.rx.request(.playingList)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToListJson()
            .mapJsonListToModelList(Entity.PlayingUser.self)
    }
    
    static func suggestionUserList() -> Single<[Entity.PlayingUser]> {
        return amongchatProvider.rx.request(.recommendedUsers)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToListJson()
            .mapJsonListToModelList(Entity.PlayingUser.self)
    }
    
    static func rtmToken() -> Single<Entity.RTMToken?> {
        //read from cache
        if let token = Settings.shared.cachedRtmToken {
            return Observable.just(Optional(token))
                .asSingle()
        }
        return Request.amongchatProvider.rx.request(.rtmToken([:]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.RTMToken.self)
            .retry(2)
            .do { token in
                guard let token = token else {
                    return
                }
                Settings.shared.cachedRtmToken = token
            }
    }
    
    static func search(_ keyword: String, skip: Int) -> Single<Entity.SearchData?> {
        let params: [String: Any] = [
            "keyword": keyword,
            "skip": skip,
            "limit": 20
        ]
        return Request.amongchatProvider.rx.request(.userSearch(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.SearchData.self)
            .retry(2)
            .observeOn(MainScheduler.asyncInstance)
    }

    static func topics() -> Single<Entity.Summary?> {
        
        return amongchatProvider.rx.request(.topics)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.Summary.self)
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func accountMetaData() -> Single<Entity.AccountMetaData?> {
        return amongchatProvider.rx.request(.accountMetaData)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.AccountMetaData.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func upload(contacts: [Entity.ContactFriend]) -> Single<Entity.ListData<Entity.ContactFriend>?> {
        return amongchatProvider.rx.request(.contactUpload(["contacts": contacts.map { $0.dictionary! }]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.ListData<Entity.ContactFriend>.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func contactList() -> Single<Entity.ListData<Entity.ContactFriend>?> {
        return amongchatProvider.rx.request(.contactList)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.ListData<Entity.ContactFriend>.self)
            .observeOn(MainScheduler.asyncInstance)
    }

    static func requestSmsCode(telRegion: String, phoneNumber: String) -> Single<Entity.SmsCodeResponse> {
        let params = [
            "client_secret" : "585ea6cf-862b-4630-9029-5ccb27a018ca",
            "zone_code" : telRegion,
            "phone" : phoneNumber,
        ]
        
        return amongchatProvider.rx.request(.requestSmsCode(params))
            .mapJSON()
            .map { item -> [String: AnyObject] in
                guard let json = item as? [String: AnyObject],
                      let code = json["code"] as? Int else {
                    throw MsgError.default
                }
                
                guard code != 10001 else {
                    throw MsgError.from(dic: json)
                }
                
                return json
            }
            .mapTo(Entity.SmsCodeResponse.self)
            .map({
                guard let response = $0 else {
                    throw MsgError.default
                }
                return response
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func verifySmsCode(code: String, telRegion: String, phoneNumber: String) -> Single<Entity.SmsCodeResponse> {
        
        let params = [
            "auth_code" : code,
            "zone_code" : telRegion,
            "phone" : phoneNumber,
        ]
        
        return amongchatProvider.rx.request(.verifySmsCode(params))
            .mapJSON()
            .map { item -> [String: AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                
                return json
            }
            .mapTo(Entity.SmsCodeResponse.self)
            .map({
                guard let response = $0 else {
                    throw MsgError.default
                }
                return response
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func uploadReceipt(restore: Bool = false) -> Single<Void> {
        
        guard let url = Bundle.main.appStoreReceiptURL, let data = NSData(contentsOf: url) else {
            let error = NSError(domain: "among.chat.iap", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot find receipt"])
            return Single.error(error)
        }
        
        let receipt = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        let params: [String : Any] = [
            "bundle_id" : Config.appBundleIdentifier,
            "receipt" : receipt,
            "restore" : restore,
        ]
        
        return amongchatProvider.rx.request(.receipt(params))
            .mapJSON()
            .map { item in
                guard let json = item as? [String: AnyObject],
                      let code = json["code"] as? Int else {
                    throw MsgError.default
                }
                
                guard code == 0 else {
                    throw MsgError.from(dic: json)
                }
            }
            .do(onSuccess: { () in
                Settings.shared.updateProfile()
            })

    }
    
    static func defaultProfileDecorations() -> Single<[Entity.DecorationCategory]?> {
        
        return amongchatProvider.rx.request(.defaultDecorations)
            .mapJSON()
            .mapToDataKeyListValue()
            .mapTo([Entity.DecorationCategory].self)
            .do(onSuccess: { (list) in
                guard let list = list else { return }
                Settings.shared.defaultProfileDecorationCategoryList.value = list
            })
    }
    
    static func unlockProfileDecoration(_ decoration: Entity.DecorationEntity) -> Single<Bool> {
        
        let params: [String : Any] = [
            "decoration_id" : decoration.id,
            "decoration_type" : decoration.decoType,
        ]
        
        return amongchatProvider.rx.request(.unlockDecoration(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (json) -> Bool in
                
                guard let process = json["process"] as? Bool,
                      process else {
                    return false
                }
                
                return true
            }
        
    }
    
    static func updateProfileDecoration(decoration: Entity.DecorationEntity, selected: Bool) -> Single<Bool> {
        
        let params: [String : Any] = [
            "decoration_id" : decoration.id,
            "decoration_type" : decoration.decoType,
            "selected" : selected ? 1 : 0,
        ]
        
        return amongchatProvider.rx.request(.updateDecoration(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (json) -> Bool in
                
                guard let process = json["process"] as? Bool,
                      process else {
                    return false
                }
                
                return true
            }
    }
    
    static func userShareSign() -> Single<String?> {
        return amongchatProvider.rx.request(.shareUserSign)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (json) -> String? in
                json["sign"] as? String
//                guard let sign = , else {
//                    return false
//                }
//
//                return true
            }
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func uploadPng(image: UIImage) -> Single<String> {
        
        guard let data = image.pngData() else {
            return Single.error(MsgError.default)
        }
        
        return amongchatProvider.rx.request(.uploadFile(data: data, ext: "png", mimeType: "image/png", type: .image))
            .mapJSON()
            .map { item -> String in
                guard let json = item as? [String: AnyObject],
                      let code = json["code"] as? Int else {
                    throw MsgError.default
                }
                
                guard code == 0,
                      let data = json["data"] as? [String: AnyObject],
                      let url = data["object_url"] as? String else {
                    throw MsgError.from(dic: json)
                }
                
                return url
            }
    }

    static func rtcToken(_ joinable: RTCJoinable) -> Single<String?> {
        let request: APIService.AmongChatBackend
        switch (joinable.rtcType ?? .agora) {
        case .agora:
            request = .agorzRtcToken(["room_id": joinable.roomId])
        case .zego:
            request = .zegoRtcToken(["room_id": joinable.roomId])
        }
        return Request.amongchatProvider.rx.request(request)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.RTCToken.self)
            .retry(2)
            .map { $0?.roomToken }
    }
    
    static func presetGameSkills() -> Single<[Entity.GameSkill]> {
        
        return amongchatProvider.rx.request(.gameSkills)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map({ data -> [[String : AnyObject]] in
                guard let list = data["topicList"] as? [[String : AnyObject]] else {
                    return []
                }
                return list
            })
            .mapTo([Entity.GameSkill].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func setGameSkill(game: Entity.GameSkill, screenshotUrl: String) -> Single<Void> {
        
        let params = [
            "topic_id" : game.topicId,
            "img" : screenshotUrl
        ]
        
        return amongchatProvider.rx.request(.setGameSkill(params))
            .mapJSON()
            .map { item in
                guard let json = item as? [String: AnyObject],
                      let code = json["code"] as? Int else {
                    throw MsgError.default
                }
                
                guard code == 0 else {
                    throw MsgError.from(dic: json)
                }
            }
            .observeOn(MainScheduler.asyncInstance)
    }

    static func removeGameSkill(game: Entity.UserGameSkill) -> Single<Void> {
        let params = [
            "topic_id" : game.topicId
        ]
        
        return amongchatProvider.rx.request(.removeGameSkill(params))
            .mapJSON()
            .map { item in
                guard let json = item as? [String: AnyObject],
                      let code = json["code"] as? Int else {
                    throw MsgError.default
                }
                
                guard code == 0 else {
                    throw MsgError.from(dic: json)
                }
            }
            .observeOn(MainScheduler.asyncInstance)
    }

    static func gameSkills(uid: Int) -> Single<[Entity.UserGameSkill]> {
        let params = [
            "uid" : uid
        ]
        
        return amongchatProvider.rx.request(.userGameSkills(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map({ data -> [[String : AnyObject]] in
                guard let list = data["game_skill_list"] as? [[String : AnyObject]] else {
                    return []
                }
                return list
            })
            .mapTo([Entity.UserGameSkill].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    //MARK: - Group
    
    static func createGroup(group: Entity.GroupProto) -> Single<Entity.Group> {
        
        guard let params = group.dictionary else {
            return Single.error(MsgError.default)
        }
        
        return amongchatProvider.rx.request(.createGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.Group.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func availableFollowersToAddToGroup(groupId: String,
                                        limit: Int = 10,
                                        skipMs: Double) -> Single<Entity.FollowersToAddToGroup> {
        
        let params: [String : Any] = [
            "gid" : groupId,
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.followersToAddToGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowersToAddToGroup.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func startChannel(groupId: String) -> Single<Entity.GroupRoom?> {
        let params: [String : Any] = [
            "gid": groupId
        ]
        return amongchatProvider.rx.request(.startGroupChannel(params))
            .mapJSON()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                if let data = json["data"] as? [String: AnyObject],
                   let roomData = data["group"] as? [String : AnyObject] {
                    return roomData
                } else {
                    throw MsgError.from(dic: json)
                }
            }
            .mapTo(Entity.GroupRoom.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func stopChannel(groupId: String) -> Single<Bool> {
        let params: [String : Any] = [
            "gid": groupId
        ]
        return amongchatProvider.rx.request(.stopGroupChannel(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func enterChannel(groupId: String) -> Single<Entity.GroupRoom?> {
        let params: [String : Any] = [
            "gid": groupId
        ]
        return amongchatProvider.rx.request(.enterGroupChannel(params))
            .mapJSON()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                if let data = json["data"] as? [String: AnyObject],
                   let roomData = data["group"] as? [String : AnyObject] {
                    return roomData
                } else {
                    throw MsgError.from(dic: json)
                }
            }
            .mapTo(Entity.GroupRoom.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func roomUserList(groupId: String) -> Single<Entity.GroupRoom?> {
        let params: [String : Any] = [
            "gid": groupId
        ]
        return amongchatProvider.rx.request(.groupLiveUserList(params))
            .mapJSON()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                if let data = json["data"] as? [String: AnyObject],
                   let roomData = data["group"] as? [String : AnyObject] {
                    return roomData
                } else {
                    throw MsgError.from(dic: json)
                }
            }
            .mapTo(Entity.GroupRoom.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func leaveChannel(groupId: String) -> Single<Bool> {
        return amongchatProvider.rx.request(.leaveGroupChannel(["gid": groupId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    
    static func addMember(_ uid: Int, to group: String) -> Single<Bool> {
        
        let params: [String : Any] = [
            "gid" : group,
            "uid" : uid
        ]
        
        return amongchatProvider.rx.request(.addMemberToGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
    }
}
