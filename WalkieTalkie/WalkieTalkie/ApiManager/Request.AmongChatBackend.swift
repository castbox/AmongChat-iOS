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

struct MsgError: Error {
    //通用错误码
    enum CodeType: Int {
        case retriveFailed = 1 //1校验失败，2没有cms权限，
        case accountBanned = 3 //3封禁，
        case deviceBanned = 4 //设备封禁，5伪造Header信息，6有新设备登录 (>1的都强制登出)
        
        case notRoomHost = 3000 //'Only the room host can operate'
        case roomSeatsFull = 3001 //'The room is full'
        case roomUserKicked = 3002 //'You are kicked off, can not enter this room'
        case notEnoughRoomCard = 3004 // no free room card for create
        case needUpgrade = 3005 //need upgrade app
        case cannotFindMatchRoom = 3007 //No channel match your language and age.
        case roomNotFound = 202 //'can not find this room'
        
        case beBlocked = 1003 //You are on this user\'s blacklist. You can not message this user any more.
        case feedDeleted = 2100
        case sendDmError = 100000
    }
    
    static let `default` = MsgError(code: 202, msg: "Please try again.", data: nil)
    
    let code: Int
    let msg: String?
    let data: [String: Any]?
    
    //帐号被封时会有此字段
    var uri: String? {
        // code 401
        if let data = data,
           let uri = data["uri"] as? String {
            return uri
        }
        return nil
    }
    
    init(code: Int,
         msg: String?,
         data: [String: Any]? = nil) {
        self.code = code
        self.msg = msg
        self.data = data
    }
    
    init(_ code: CodeType,
         msg: String? = nil,
         data: [String: Any]? = nil) {
        self.code = code.rawValue
        self.msg = msg
        self.data = data
    }
    
    var codeType: CodeType? {
        return CodeType(rawValue: code)
    }
    
    static func from(dic: [String: Any]) -> MsgError {
        guard let code = dic["code"] as? Int else {
            return .default
        }
        return MsgError(code: code, msg: dic["msg"] as? String, data: dic["data"] as? [String: Any])
    }
}

extension MsgError.CodeType {
    
    var tips: String? {
        switch self {
        case .needUpgrade:
            return R.string.localizable.forceUpgradeTip()
        case .roomUserKicked:
            return R.string.localizable.enterKickedRoomTips()
        case .cannotFindMatchRoom:
            return R.string.localizable.adminCannotMatchedRoomTips()
        case .beBlocked:
            return R.string.localizable.dmSendMessageBeblockedError()
        case .feedDeleted:
            return R.string.localizable.feedDeletedTips()
        default:
            return nil
        }
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
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject],  let code = json["code"] as? Int else {
                    throw MsgError.default
                }
                guard code == 0, let data = json["data"] as? [String: AnyObject] else {
                    throw MsgError.from(dic: json)
                }
                return data
            }
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
            .do(onNext: { item in
                guard let profile = item else {
                    return
                }
                DMManager.shared.update(profile: profile.dmProfile)
            })
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
    
    static func enterRoom(roomId: String? = nil, topicId: String?, source: String? = nil) -> Single<Entity.RoomInfo?> {
        
        var paras = [String : Any]()
        if let rid = roomId { paras["room_id"] = rid }
        paras["topic_id"] = topicId
        if let s = source { paras["source"] = s }
        paras["rtc_support"] = "agora,zego"
        return amongchatProvider.rx.request(.enteryRoom(paras))
            .mapJSON()
//            .mapToDataKeyJsonValue()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                if let data = json["data"] as? [String: AnyObject],
                   let _ = data["room"] as? [String : AnyObject] {
                    return data
                } else {
                    throw MsgError.from(dic: json)
                }
            }
            .mapTo(Entity.RoomInfo.self)
            .observeOn(MainScheduler.asyncInstance)
            .do { info in
                guard let info = info, info.isSilentValue, !Settings.isSilentUser else { return }
                Settings.shared.updateProfile()
            }
    }
    
    static func createRoom(_ room: Entity.RoomProto) -> Single<Entity.RoomInfo?> {
        
        guard var params = room.dictionary else {
            return Observable.just(nil).asSingle()
        }
        params["rtc_support"] = "agora,zego"

        return amongchatProvider.rx.request(.createRoom(params))
            .mapJSON()
//            .mapToDataKeyJsonValue()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                if let data = json["data"] as? [String: AnyObject],
                   let _ = data["room"] as? [String : AnyObject] {
                    return data
                } else {
                    throw MsgError.from(dic: json)
                }
            }
            .mapTo(Entity.RoomInfo.self)
            .observeOn(MainScheduler.asyncInstance)
            .do { info in
                guard let info = info, info.isSilentValue, !Settings.isSilentUser else { return }
                Settings.shared.updateProfile()
            }
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
            .do(onSuccess: { (page) in
                
                guard let profile = page?.profile else { return }
                
                let _ = NoticeManager.shared.queryMessageBody(objType: Entity.NoticeMessage.MessageObjType.user.rawValue, objId: profile.uid.string)
                    .flatMap { (m) -> Single<Void> in
                        guard var messageBody = m else {
                            return Single.just(())
                        }
                        
                        messageBody.img = profile.pictureUrl
                        if let name = profile.name {
                            messageBody.title = name
                        }
                        
                        return NoticeManager.shared.updateMessageBody(messageBody)
                    }
                    .subscribe { (_) in
                        
                    } onError: { (_) in
                        
                    }
            })
            .do(onNext: { item in
                guard let profile = item?.profile else {
                    return
                }
                DMManager.shared.update(profile: profile.dmProfile)
            })
            .do(onSuccess: { item in
                guard let profile = item?.profile else {
                    return
                }
                
                let _ = FollowingUsersManager.shared.updateUser(profile).subscribe()
            })

    }
    
    /// type: follow / block
    static func follow(uid: Int, type: String) -> Single<Bool> {
        let paras = ["target_uid": uid, "relation_type": type] as [String : Any]
        return amongchatProvider.rx.request(.follow(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .do(onSuccess: { json in
                guard type == "follow" else { return }
                
                guard let userJson = json["user"],
                      let user = JSONDecoder().mapTo(Entity.UserProfile.self, from: userJson) else { return }
                
                let _ = FollowingUsersManager.shared.addUsers([user]).subscribe()
                
            })
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
            .do(onSuccess: { success in
                guard success, type == "follow" else { return }
                let _ = FollowingUsersManager.shared.removeUser(uid).subscribe()
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func relationData(uid: Int) -> Single<Entity.RelationData?> {
        let paras = ["target_uid": uid]
        return amongchatProvider.rx.request(.relationData(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.RelationData.self)
            .observeOn(MainScheduler.asyncInstance)
            .do { data in
                guard let data = data, uid == Settings.loginUserId else {
                    return
                }
                var profilePage = Settings.profilePage
                profilePage?.followData = data
                Settings.shared.profilePage.value = profilePage
            }
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
    
    static func followingList(uid: Int, limit: Int = 20, skipMs: Double) -> Single<Entity.FollowData> {
        
        let paras: [String : Any] = [
            "relation_type": "follow",
            "uid": uid,
            "limit": limit,
            "skip_ms": skipMs,
            "with_follower" : 1
        ]
        
        return amongchatProvider.rx.request(.followingList(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .map({
                guard let data = $0 else {
                    throw MsgError.default
                }
                return data
            })
            .do(onSuccess: { data in
                guard uid.isSelfUid else { return }
                let _ = FollowingUsersManager.shared.addUsers(data.list).subscribe()
            })
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
    
    static func groupRoomInviteFriends(gid: String, skipMs: Double) -> Single<Entity.FollowData?> {
        let paras = ["gid": gid, "limit": limit, "skip_ms": skipMs] as [String : Any]
        return amongchatProvider.rx.request(.groupRoomInviteFriends(paras))
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
            "with_code" : 1,
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
            .do(onSuccess: { (summary) in
                guard let summary = summary else { return }
                Settings.shared.supportedTopics.value = summary
            })
        
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

    static func requestSmsCode(telRegion: String, phoneNumber: String, recaptchaToken: String) -> Single<Entity.SmsCodeResponse> {
        let params = [
            "client_secret" : "585ea6cf-862b-4630-9029-5ccb27a018ca",
            "zone_code": telRegion,
            "phone": phoneNumber,
            "token": recaptchaToken,
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
        let params = [
            "with_hide" : 1
        ]
        return amongchatProvider.rx.request(.defaultDecorations(params))
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
        
        return uploadData(data, ext: "png", mimeType: "image/png", type: .image)
    }
    
    static func uploadData(_ data: Data, ext: String, mimeType: String, type: APIService.AmongChatBackend.FileType) -> Single<String> {
        return amongchatProvider.rx.request(.uploadFile(data: data, ext: ext, mimeType: mimeType, type: type))
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
    
    static func uploadAsJpg(image: UIImage, compressing: CGFloat = 0.4) -> Single<String> {
        
        guard let data = image.jpegData(compressionQuality: compressing) else {
            return Single.error(MsgError.default)
        }
        
        return uploadData(data, ext: "jpeg", mimeType: "image/jpg", type: .image)
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
                                        skipMs: Double) -> Single<Entity.GroupUserList> {
        
        let params: [String : Any] = [
            "gid" : groupId,
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.followersToAddToGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.GroupUserList.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func startChannel(groupId: String) -> Single<Entity.Group?> {
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
            .mapTo(Entity.Group.self)
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
    
    static func enterChannel(groupId: String) -> Single<Entity.GroupInfo?> {
        let params: [String : Any] = [
            "gid": groupId
        ]
        return amongchatProvider.rx.request(.enterGroupChannel(params))
            .mapJSON()
//            .mapToDataKeyJsonValue()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject] else {
                    throw MsgError.default
                }
                if let data = json["data"] as? [String: AnyObject],
                   let processed = data["processed"] as? Bool {
                    if processed {
                        return data
                    } else {
                        //未开播
                        throw MsgError(code: 202, msg: R.string.localizable.enterClosedGroupRoomTips(), data: nil)
                    }
                } else {
                    throw MsgError.from(dic: json)
                }
            }
            .mapTo(Entity.GroupInfo.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
//    static func roomUserList(groupId: String) -> Single<Entity.Group?> {
//        let params: [String : Any] = [
//            "gid": groupId
//        ]
//        return amongchatProvider.rx.request(.groupLiveUserList(params))
//            .mapJSON()
//            .map { item -> [String : AnyObject] in
//                guard let json = item as? [String: AnyObject] else {
//                    throw MsgError.default
//                }
//                if let data = json["data"] as? [String: AnyObject],
//                   let roomData = data["group"] as? [String : AnyObject] {
//                    return roomData
//                } else {
//                    throw MsgError.from(dic: json)
//                }
//            }
//            .mapTo(Entity.Group.self)
//            .observeOn(MainScheduler.asyncInstance)
//    }
    
    
    static func groupLiveUserList(_ groupId: String,
                               limit: Int = 20,
                               skipMs: Double) -> Single<Entity.GroupUserList> {
        
        let params: [String : Any] = [
            "gid" : groupId,
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.groupLiveUserList(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.GroupUserList.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func leaveChannel(groupId: String) -> Single<Bool> {
        return amongchatProvider.rx.request(.leaveGroupChannel(["gid": groupId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func groupCheckHaveLive() -> Single<Entity.Group?> {
        return amongchatProvider.rx.request(.groupCheckHaveLive)
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
            .mapTo(Entity.Group.self)
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
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupList(skip: Int, limit: Int = 20) -> Single<[Entity.Group]> {
        
        let params: [String : Any] = [
            "skip" : skip,
            "limit" : limit,
        ]
        
        return amongchatProvider.rx.request(.groupList(params))
            .mapJSON()
            .mapToDataKeyListKeyValue()
            .mapTo([Entity.Group].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func myGroupList(skip: Int, limit: Int = 20) -> Single<[Entity.Group]> {
        
        let params: [String : Any] = [
            "skip" : skip,
            "limit" : limit,
        ]
        
        return amongchatProvider.rx.request(.myGroupList(params))
            .mapJSON()
            .mapToDataKeyListKeyValue()
            .mapTo([Entity.Group].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupListOfHost(_ hostUid: Int, skip: Int, limit: Int = 20) -> Single<[Entity.Group]> {
        
        let params: [String : Any] = [
            "uid" : hostUid,
            "skip" : skip,
            "limit" : limit,
        ]
        
        return amongchatProvider.rx.request(.groupListOfHost(params))
            .mapJSON()
            .mapToDataKeyListKeyValue()
            .mapTo([Entity.Group].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupListOfUserJoined(_ uid: Int, skip: Int, limit: Int = 20) -> Single<[Entity.Group]> {
        
        let params: [String : Any] = [
            "uid" : uid,
            "skip" : skip,
            "limit" : limit,
        ]
        
        return amongchatProvider.rx.request(.groupListOfJoined(params))
            .mapJSON()
            .mapToDataKeyListKeyValue()
            .mapTo([Entity.Group].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func appliedUsersOfGroup(_ groupId: String,
                                    limit: Int = 10,
                                    skipMs: Double) -> Single<Entity.GroupUserList> {
        
        let params: [String : Any] = [
            "gid" : groupId,
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.groupAppliedUserList(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.GroupUserList.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
    }

    static func membersOfGroup(_ groupId: String,
                               limit: Int = 20,
                               skipMs: Double) -> Single<Entity.GroupUserList> {
        
        let params: [String : Any] = [
            "gid" : groupId,
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.groupMemberList(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.GroupUserList.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupInfo(_ groupId: String) -> Single<Entity.GroupInfo> {
        
        let params: [String : Any] = [
            "gid" : groupId
        ]
        
        return amongchatProvider.rx.request(.groupInfo(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.GroupInfo.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { (info) in
                
                let _ = NoticeManager.shared.queryMessageBody(objType: Entity.NoticeMessage.MessageObjType.group.rawValue, objId: info.group.gid)
                    .flatMap { (m) -> Single<Void> in
                        guard var messageBody = m else {
                            return Single.just(())
                        }
                        
                        messageBody.img = info.group.cover
                        messageBody.title = info.group.name
                        
                        return NoticeManager.shared.updateMessageBody(messageBody)
                    }
                    .subscribe { (_) in
                        
                    } onError: { (_) in
                        
                    }
            })
    }
    
    static func leaveGroup(_ groupId: String) -> Single<Bool> {
        
        let params: [String : Any] = [
            "gid" : groupId
        ]
        
        return amongchatProvider.rx.request(.leaveGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }

    static func applyToJoinGroup(_ groupId: String) -> Single<Bool> {
        
        let params: [String : Any] = [
            "gid" : groupId
        ]
        
        return amongchatProvider.rx.request(.applyToJoinGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func update(_ group: Entity.Group) -> Single<Entity.Group?> {
        guard var params = group.dictionary else {
            return Observable<Entity.Group?>.empty().asSingle()
        }
        params.removeValue(forKey: "userList")
        return amongchatProvider.rx.request(.updateGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.Group.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateNickName(_ nickName: String, groupId: String, topic: AmongChat.Topic) -> Single<Bool> {
        return amongchatProvider.rx.request(.groupNickName(["name_\(topic.rawValue)": nickName, "gid": groupId]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateGroup(_ groupId: String, groupData: Entity.GroupProto) -> Single<Entity.Group> {
        
        guard var params = groupData.dictionary else {
            return Observable<Entity.Group>.empty().asSingle()
        }
        
        params["gid"] = groupId
        
        return amongchatProvider.rx.request(.updateGroup(params))
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
    
    static func handleGroupApply(of uid: Int, groupId: String, accept: Bool) -> Single<Bool> {
        
        let params: [String : Any] = ["gid" : groupId, "uid": uid, "accept": accept.int]
        
        return amongchatProvider.rx.request(.handleGroupApply(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupRoomSeatAdd(_ groupId: String, uid: Int, in position: Int) -> Single<Entity.Group?> {
        let params: [String : Any] = ["gid" : groupId, "uid": uid, "seat_no": position]
        return amongchatProvider.rx.request(.groupRoomSeatAdd(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map({ data -> [String : AnyObject] in
                guard let group = data["group"] as? [String : AnyObject] else {
                    return [:]
                }
                return group
            })
            .mapTo(Entity.Group.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupRoomSeatRemove(_ groupId: String, uid: Int) -> Single<Entity.Group?> {
        let params: [String : Any] = ["gid" : groupId, "uid": uid]
        return amongchatProvider.rx.request(.groupRoomSeatRemove(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map({ data -> [String : AnyObject] in
                guard let group = data["group"] as? [String : AnyObject] else {
                    return [:]
                }
                return group
            })
            .mapTo(Entity.Group.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupRoomInviteUser(gid: String, uid: Int, isStranger: Bool) -> Single<Entity.FollowData?> {
        let paras = ["gid": gid, "uid": uid, "is_stranger": isStranger.int] as [String : Any]
        return amongchatProvider.rx.request(.groupRoomInviteUser(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FollowData.self)
            .observeOn(MainScheduler.asyncInstance)
    }

    static func deleteGroup(_ groupId: String) -> Single<Bool> {
        
        let params: [String : Any] = ["gid" : groupId]
        
        return amongchatProvider.rx.request(.deleteGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func groupStatus(_ groupId: String) -> Single<Entity.Group?> {
        
        let params: [String : Any] = ["gid" : groupId]
        
        return amongchatProvider.rx.request(.groupStatus(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map({ data -> [String : AnyObject] in
                guard let group = data["group"] as? [String : AnyObject] else {
                    return [:]
                }
                return group
            })
            .mapTo(Entity.Group.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func kickMemberFromGroup(_ groupId: String, uids: [Int]) -> Single<Bool> {
        
        let params: [String : Any] = [
            "gid" : groupId,
            "uids" : uids
        ]
        
        return amongchatProvider.rx.request(.kickMemberFromGroup(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }

    static func reportReasons() -> Single<Entity.Report?> {
        return amongchatProvider.rx.request(.reportReasons)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.Report.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    /// 举报用户或直播间
    static func reportContent(type: Report.ReportType, targetID: String, reasonID: Int, note: String? = nil, pics: [String] = [], roomId: String = "", operate: Report.ReportOperate?) -> Single<Bool> {
        
        var paras: [String: Any] = ["report_type": type.rawValue, "target_id": targetID, "reason_id": reasonID, "note": note ?? "", "operate": operate?.rawValue ?? ""]
        // 额外证据
        paras["extra"] = [
            "pics": pics,
            "room_id": roomId
        ]
        return amongchatProvider.rx.request(.report(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func adminKick(user uid: String, roomId: String) -> Single<Bool> {
        let paras: [String: Any] = ["target_uid": uid, "room_id": roomId]
        return amongchatProvider.rx.request(.adminKickUser(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func adminMuteMic(user uid: String, roomId: String) -> Single<Bool> {
        let paras: [String: Any] = ["target_uid": uid, "room_id": roomId]
        return amongchatProvider.rx.request(.adminMuteMic(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func adminUnmuteMic(user uid: String, roomId: String) -> Single<Bool> {
        let paras: [String: Any] = ["target_uid": uid, "room_id": roomId]
        return amongchatProvider.rx.request(.adminUnmuteMic(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }

    static func adminMuteIm(user uid: String, roomId: String) -> Single<Bool> {
        let paras: [String: Any] = ["target_uid": uid, "room_id": roomId]
        return amongchatProvider.rx.request(.adminMuteIm(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func adminUnmuteIm(user uid: String, roomId: String) -> Single<Bool> {
        let paras: [String: Any] = ["target_uid": uid, "room_id": roomId]
        return amongchatProvider.rx.request(.adminUnmuteIm(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func roomMuteInfo(user uid: String, roomId: String) -> Single<Entity.UserMuteInfo?> {
        let paras: [String: Any] = ["target_uid": uid, "room_id": roomId]
        return amongchatProvider.rx.request(.roomMuteInfo(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.UserMuteInfo.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func noticeCheck(lastCheckMs: Int64, interactiveMsgReadMs: Int64) -> Single<(Bool, Bool)> {
        
        let params: [String : Any] = [
            "read_ms" : lastCheckMs,
            "i_read_ms": interactiveMsgReadMs,
        ]
        
        return amongchatProvider.rx.request(.noticeCheck(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (data) in
                let unread_g = data["unread_g"] as? Bool ?? false
                let unread_p = data["unread_p"] as? Bool ?? false
                let unread_ga = data["unread_ga"] as? Bool ?? false
                let unread_i = data["unread_i"] as? Bool ?? false
                return ((unread_g || unread_p || unread_ga), unread_i)
            }
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func peerNoticeMessge(skipMs: Int64) -> Single<[Entity.Notice]> {
        
        let params: [String : Any] = [
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.peerMessage(params))
            .mapJSON()
            .mapToDataKeyListKeyValue()
            .mapTo([Entity.Notice].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func globalNoticeMessage(skipMs: Int64) -> Single<[Entity.Notice]> {
        
        let params: [String : Any] = [
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.globalMessage(params))
            .mapJSON()
            .mapToDataKeyListKeyValue()
            .mapTo([Entity.Notice].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func myGroupApplyStat() -> Single<[Entity.GroupApplyStat]> {
        return amongchatProvider.rx.request(.myGroupApplyStat)
            .mapJSON()
            .mapToDataKeyListKeyValue()
            .mapTo([Entity.GroupApplyStat].self)
            .map {
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            }
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateInstalled(_ gameBundleIds: [String]) -> Single<Bool> {
        return amongchatProvider.rx.request(.updateInstalledGames(["games": gameBundleIds.joined(separator: ",")]))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
    }
    

    static func sendDm(message: Entity.DMMessageBody, to uid: String) -> Single<Bool> {
        let request: APIService.AmongChatBackend
        switch message.msgType {
        case .text:
            request = .sendDM(["uid": uid, "type": message.type, "text": message.text ?? ""])
        case .gif:
            guard let url = message.img, let imageWidth = message.imageWidth, let imageHeight = message.imageHeight else {
                return .error(MsgError(.sendDmError))
            }
            request = .sendDM(["uid": uid, "type": message.type, "img": url, "img_width": imageWidth, "img_height": imageHeight])
        case .voice:
            guard let url = message.url, let duration = message.duration else {
                return .error(MsgError(.sendDmError))
            }
            request = .sendDM(["uid": uid, "type": message.type, "url": url, "duration": duration])
        default:
            return .error(MsgError(.sendDmError))
        }
        return amongchatProvider.rx.request(request)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func userStatus(_ uid: Int) -> Single<Entity.UserStatus?> {
        let paras: [String: Any] = ["uid": uid]
        return amongchatProvider.rx.request(.userStatus(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.UserStatus.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func createFeed(proto: Entity.FeedProto) -> Single<Void> {
        
        guard let params = proto.dictionary else {
            return Single.error(MsgError.default)
        }
        
        return amongchatProvider.rx.request(.feedCreate(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { (data) in
                guard let _ = data["pid"] else {
                    throw MsgError.default
                }
                
                return
            }
    }
    
    static func feedCommentList(ofPost pid: String, skipMs: Int64 = 0, limit: Int = 10) -> Single<Entity.FeedCommentList> {
        
        let params: [String : Any]  = [
            "pid" : pid,
            "skip_ms" : skipMs,
            "limit" : limit
        ]
        
        return amongchatProvider.rx.request(.commentList(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FeedCommentList.self)
            .map({
                guard let list = $0 else {
                    throw MsgError.default
                }
                return list
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func commentReplyList(ofComment cid: String, skipMs: Int64 = 0, limit: Int = 10) -> Single<Entity.CommentReplyList> {
        
        let params: [String : Any]  = [
            "cid" : cid,
            "skip_ms" : skipMs,
            "limit" : limit
        ]
        
        return amongchatProvider.rx.request(.commentReplyList(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.CommentReplyList.self)
            .map({
                guard let list = $0 else {
                    throw MsgError.default
                }
                return list
            })
            .observeOn(MainScheduler.asyncInstance)
    }

    static func replyToComment(_ cid: String, toUid: Int? = nil, text: String) -> Single<Entity.FeedCommentReply> {
        
        var params: [String : Any]  = [
            "cid" : cid,
            "text" : text
        ]
        
        if let toUid = toUid {
            params["to_uid"] = toUid
        }
        
        return amongchatProvider.rx.request(.createReply(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FeedCommentReply.self)
            .map({
                guard let reply = $0 else {
                    throw MsgError.default
                }
                return reply
            })
            .observeOn(MainScheduler.asyncInstance)

    }
    
    static func likeComment(_ cid: String) -> Single<Bool> {
        
        let params: [String : Any]  = [
            "obj_id" : cid,
            "type" : "like_c"
        ]
                
        return amongchatProvider.rx.request(.likeComment(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)

    }
    
    static func cancelLikingComment(_ cid: String) -> Single<Bool> {
        
        let params: [String : Any]  = [
            "obj_id" : cid,
            "type" : "like_c"
        ]
                
        return amongchatProvider.rx.request(.cancelLikingComment(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)

    }
    
    static func deleteReply(_ rid: String) -> Single<Bool> {
        
        let params: [String : Any]  = [
            "rid" : rid
        ]
                
        return amongchatProvider.rx.request(.deleteReply(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }

    static func createComment(toFeed pid: String, text: String) -> Single<Entity.FeedComment> {
        
        let params: [String : Any]  = [
            "pid" : pid,
            "text" : text
        ]
                
        return amongchatProvider.rx.request(.createComment(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FeedComment.self)
            .map({
                guard let comment = $0 else {
                    throw MsgError.default
                }
                return comment
            })
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func deleteComment(_ cid: String) -> Single<Bool> {
        
        let params: [String : Any] = [
            "cid" : cid
        ]
                
        return amongchatProvider.rx.request(.deleteComment(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func claimWelfare(code: String) -> Single<Bool> {
        
        let params: [String : Any] = [
            "code" : code
        ]
                
        return amongchatProvider.rx.request(.claimWelfare(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    
    static func sendDMPushToAnonymousUser(_ uid: String) -> Single<Bool> {
        
        let params: [String : Any]  = [
            "uid" : uid
        ]
                
        return amongchatProvider.rx.request(.sendDMPushToAnonymousUser(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func feedShareUserList(_ uids: [String]) -> Single<[Entity.UserProfile]?> {
        
        let params: [String : Any]  = [
            "uids_dm" : uids.suffix(20).joined(separator: ",")
        ]
                
        return amongchatProvider.rx.request(.feedShareUserList(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToListJson()
            .mapTo([Entity.UserProfile].self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func feedShareToUser(_ feed: Entity.Feed, uids: [Int], text: String) -> Single<Entity.FeedShareResult?> {
        
        let params: [String : Any] = [
            "pid": feed.pid,
            "uids": uids,
            "text": text
        ]
                
        return amongchatProvider.rx.request(.feedShareToUser(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FeedShareResult.self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { result in
                guard let result = result else {
                    return
                }
                let uids = result.uids + result.uidsBlock
                uids.map { Conversation.ViewModel($0.string) }
                    .forEach { $0.sendFeedMessage(with: feed, text: text, isSuccess: result.uids.contains($0.targetUid.int64Value))
                    }
            })
            .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
    }
}
