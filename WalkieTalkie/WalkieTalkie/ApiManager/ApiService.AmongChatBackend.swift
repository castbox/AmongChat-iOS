//
//  ApiService.AmongChatBackend.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import Alamofire

extension APIService {
    enum AmongChatBackend {
        case login([String : Any])
        case logout
        case createRoom([String : Any])
        case enteryRoom([String : Any])
        //        case roomUpdate([String: Any])
        case updateNickName([String: Any])
        case heartBeating([String: Any])
        case agorzRtcToken([String: Any])
        case zegoRtcToken([String: Any])
        case rtmToken([String: Any])
        case leaveRoom([String: Any])
        case roomInfo([String: Any])
        case updateRoomInfo([String : Any])
        case kickUsers([String : Any])
        case summary([String : Any])
        case roomNickName([String: Any])
        case groupNickName([String: Any])
        case profile([String : Any])
        case updateProfile([String : Any])
        case defaultAvatars([String : Any])
        case firebaseToken([String: Any])
        case unlockAvatar([String : Any])
        case sensitiveWords
        case updateDevice([String: Any])
        case globalSetting
        case follow([String: Any])
        case unFollow([String: Any])
        case relationData([String: Any])
        case blockList([String: Any])
        case followingList([String: Any])
        case followerList([String: Any])
        case profilePage([String: Any])
        case playingList
        case recommendedUsers
        case exitRoomRecommend([String: Any])
        case inviteFriends([String: Any])
        case groupRoomInviteFriends([String: Any])
        case inviteUser([String: Any])
        case onlineStrangers
        case userSearch([String: Any])
        case contactUpload([String: Any])
        case contactList
        case topics
        case accountMetaData
        case requestSmsCode([String : Any])
        case verifySmsCode([String : Any])
        case receipt([String : Any])
        case defaultDecorations
        case unlockDecoration([String : Any])
        case updateDecoration([String : Any])
        case shareUserSign
        case uploadFile(data: Data, ext: String, mimeType: String, type: FileType)
        case gameSkills
        case setGameSkill([String : Any])
        case removeGameSkill([String : Any])
        case userGameSkills([String : Any])
        case startGroupChannel([String : Any])
        case stopGroupChannel([String: Any])
        case enterGroupChannel([String : Any])
        case leaveGroupChannel([String : Any])
        case createGroup([String : Any])
        case groupCheckHaveLive
        case followersToAddToGroup([String : Any])
        case addMemberToGroup([String : Any])
        case groupLiveUserList([String: Any])
        case groupRoomSeatAdd([String: Any])
        case groupRoomSeatRemove([String: Any])
        case groupRoomInviteUser([String: Any])
        case updateGroup([String: Any])
        case groupList([String : Any])
        case myGroupList([String : Any])
        case groupListOfHost([String : Any])
        case groupListOfJoined([String : Any])
        case groupAppliedUserList([String : Any])
        case groupMemberList([String : Any])
        case groupInfo([String : Any])
        case leaveGroup([String : Any])
        case applyToJoinGroup([String : Any])
        case deleteGroup([String : Any])
        case handleGroupApply([String: Any])
        case kickMemberFromGroup([String : Any])
        
        //report
        case reportReasons
        case report([String: Any])
        case adminKickUser([String: Any])
        case adminMuteMic([String: Any])
        case adminUnmuteMic([String: Any])
        case adminMuteIm([String: Any])
        case adminUnmuteIm([String: Any])
        case roomMuteInfo([String: Any])
        
    }
}

extension APIService.AmongChatBackend: TargetType {
    var baseURL: URL {
        let url: String
        switch Config.environment {
        case .debug:
            url = "https://dev.api.among.chat"
        case .release:
            url = "https://api.among.chat"
        }
        return URL(string: url)!
    }
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .summary:
            return"/api/v1/summary"
        case .createRoom:
            return "/api/v1/rooms/create"
        case .enteryRoom:
            return "/api/v1/rooms/enter"
        case .updateNickName:
            return "/api/v1/rooms/nickname"
        case .heartBeating:
            return "/api/v1/rooms/heartbeat"
        case .agorzRtcToken:
            return "/live/room/token"
        case .zegoRtcToken:
            return "/live/room/token/zego"
        case .rtmToken:
            return "/live/token/agora"
        case .leaveRoom:
            return "/api/v1/rooms/leave"
        case .roomInfo:
            return "/api/v1/rooms/room"
        case .updateRoomInfo:
            return "/api/v1/rooms/update"
        case .kickUsers:
            return "/api/v1/rooms/kick"
        case .profile:
            return "/account/profile"
        case .updateProfile:
            return "/account/profile"
        case .roomNickName:
            return "/api/v1/rooms/nickname"
        case .logout:
            return "auth/logout"
        case .defaultAvatars:
            return "/account/default/avatars"
        case .firebaseToken:
            return "/auth/firebase/token"
        case .unlockAvatar:
            return "/account/unlock/avatar"
        case .updateDevice:
            return "/account/device"
        case .sensitiveWords:
            return "/live/keyword/blacklist"
        case .globalSetting:
            return "/api/v1/setting"
        case .follow:
            return "/social/relation"
        case .unFollow:
            return "/social/relation"
        case .relationData:
            return "/social/relation/data"
        case .blockList:
            return "/social/relation"
        case .followingList:
            return "/social/relation"
        case .followerList:
            return "/social/relation/followers"
        case .profilePage:
            return "/account/profile/page"
        case .playingList:
            return "/api/v1/friends/play/list"
        case .recommendedUsers:
            return "/api/v1/recommend/user/list"
        case .exitRoomRecommend:
            return "/api/v1/end/user/list"
        case .inviteFriends:
            return "/social/relation/friends"
        case .groupRoomInviteFriends:
            return "/social/relation/group/live/followers"
        case .inviteUser:
            return "/api/v1/rooms/invite"
        case .onlineStrangers:
            return "/api/v1/online/stranger/list"
        case .userSearch:
            return "/live/user/search"
        case .contactUpload:
            return "/api/v1/contact/upload"
        case .contactList:
            return "/api/v1/contact/invite/list"
        case .topics:
            return "/api/v1/topics"
        case .accountMetaData:
            return "/account/meta_data"
        case .requestSmsCode:
            return "/auth/phone/send_code"
        case .verifySmsCode:
            return "/auth/phone/verify"
        case .receipt:
            return "/purchase/ios/receipt"
        case .defaultDecorations:
            return "/account/default/decoration"
        case .unlockDecoration:
            return "/account/unlock/decoration"
        case .updateDecoration:
            return "/account/decoration/upsert"
        case .shareUserSign:
            return "/account/share/sign"
        case .uploadFile:
            return "/tool/file/upload"
        case .gameSkills:
            return "/api/v1/topics/skill"
        case .setGameSkill:
            return "/api/v1/game/skill"
        case .removeGameSkill:
            return "/api/v1/game/skill"
        case .userGameSkills:
            return "/api/v1/game/skill/list"
        case .startGroupChannel:
            return "/api/v1/group/live/start"
        case .stopGroupChannel:
            return "/api/v1/group/live/stop"
        case .enterGroupChannel:
            return "/api/v1/group/live/enter"
        case .leaveGroupChannel:
            return "/api/v1/group/live/leave"
        case .groupLiveUserList:
            return "/api/v1/group/live/user/list"
        case .createGroup:
            return "/api/v1/group/create"
        case .groupCheckHaveLive:
            return "/api/v1/group/live/check"
        case .followersToAddToGroup:
            return "/social/relation/group/followers"
        case .addMemberToGroup:
            return "/api/v1/group/member"
        case .updateGroup:
            return "/api/v1/group/update"
        case .groupNickName:
            return "/api/v1/group/live/nickname"
        case .groupList:
            return "/api/v1/group/list"
        case .myGroupList:
            return "/api/v1/my/group/list"
        case .groupListOfHost:
            return "/api/v1/user/host/group/list"
        case .groupListOfJoined:
            return "/api/v1/user/join/group/list"
        case .groupRoomSeatAdd:
            return "/api/v1/group/seats/add"
        case .groupRoomSeatRemove:
            return "/api/v1/group/seats/remove"
        case .groupAppliedUserList:
            return "/api/v1/group/apply/list"
        case .groupMemberList:
            return "/api/v1/group/member/list"
        case .groupRoomInviteUser:
            return "/api/v1/group/invite"
        case .groupInfo:
            return "/api/v1/group/page"
        case .leaveGroup:
            return "/api/v1/group/leave"
        case .applyToJoinGroup:
            return "/api/v1/group/apply"
        case .deleteGroup:
            return "/api/v1/group"
        case .handleGroupApply:
            return "/api/v1/group/apply/handle"
        case .kickMemberFromGroup:
            return "/api/v1/group/member"
        case .reportReasons:
            return "/live/report/reason"
        case .report:
            return "/live/report/content"
        case .adminKickUser:
            return "/api/v1/rooms/out"
        case .adminMuteMic:
            return "/api/v1/rooms/mute"
        case .adminUnmuteMic:
            return "/api/v1/rooms/unmute"
        case .adminMuteIm:
            return "/api/v1/rooms/im/mute"
        case .adminUnmuteIm:
            return "/api/v1/rooms/im/unmute"
        case .roomMuteInfo:
            return "/api/v1/rooms/mute/info"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login,
             .createRoom,
             .updateNickName,
             .updateRoomInfo,
             .kickUsers,
             .updateProfile,
             .roomNickName,
             .unlockAvatar,
             .updateDevice,
             .inviteUser,
             .receipt,
             .contactUpload,
             .unlockDecoration,
             .updateDecoration,
             .setGameSkill,
             .createGroup,
             .addMemberToGroup,
             .groupLiveUserList,
             .groupRoomInviteUser,
             .groupNickName,
             .updateGroup,
             .applyToJoinGroup,
             .handleGroupApply,
             .report,
             .adminKickUser,
             .adminMuteMic,
             .adminUnmuteMic,
             .adminMuteIm,
             .adminUnmuteIm,
             .logout:
            return .post
            
        case .summary,
             .enteryRoom,
             .heartBeating,
             .rtmToken,
             .agorzRtcToken,
             .zegoRtcToken,
             .profile,
             .leaveRoom,
             .defaultAvatars,
             .roomInfo,
             .sensitiveWords,
             .globalSetting,
             .firebaseToken,
             .relationData,
             .blockList,
             .followingList,
             .followerList,
             .profilePage,
             .recommendedUsers,
             .playingList,
             .inviteFriends,
             .groupRoomInviteFriends,
             .exitRoomRecommend,
             .onlineStrangers,
             .topics,
             .accountMetaData,
             .contactList,
             .requestSmsCode,
             .verifySmsCode,
             .defaultDecorations,
             .userSearch,
             .gameSkills,
             .startGroupChannel,
             .stopGroupChannel,
             .enterGroupChannel,
             .leaveGroupChannel,
             .groupCheckHaveLive,
             .userGameSkills,
             .followersToAddToGroup,
             .groupList,
             .myGroupList,
             .groupListOfHost,
             .groupListOfJoined,
             .groupRoomSeatAdd,
             .groupRoomSeatRemove,
             .groupAppliedUserList,
             .groupMemberList,
             .groupInfo,
             .leaveGroup,
             .reportReasons,
             .roomMuteInfo,
             .shareUserSign:
            return .get
        case .follow:
            return .put
        case .removeGameSkill,
             .deleteGroup,
             .kickMemberFromGroup,
             .unFollow:
            return .delete
            
        case .uploadFile:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data(capacity: 10)
    }
    
    var task: Task {
        switch self {
        case .enteryRoom(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
            
        case .logout,
             .sensitiveWords,
             .playingList,
             .recommendedUsers,
             .onlineStrangers,
             .topics,
             .accountMetaData,
             .contactList,
             .groupCheckHaveLive,
             .defaultDecorations,
             .globalSetting,
             .gameSkills,
             .reportReasons,
             .shareUserSign:
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
            
        case .createRoom(let params),
             .updateProfile(let params),
             .updateRoomInfo(let params),
             .updateGroup(let params),
             .receipt(let params),
             .contactUpload(let params),
             .createGroup(let params),
             .kickMemberFromGroup(let params),
             .report(let params),
             .adminKickUser(let params),
             .adminMuteMic(let params),
             .adminUnmuteMic(let params),
             .adminMuteIm(let params),
             .adminUnmuteIm(let params),
             .updateDevice(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .login(let params),
             .summary(let params),
             .updateNickName(let params),
             .heartBeating(let params),
             .roomInfo(let params),
             .agorzRtcToken(let params),
             .zegoRtcToken(let params),
             .rtmToken(let params),
             .leaveRoom(let params),
             .kickUsers(let params),
             .roomNickName(let params),
             .defaultAvatars(let params),
             .unlockAvatar(let params),
             .relationData(let params),
             .profile(let params),
             .profilePage(let params),
             .firebaseToken(let params),
             .blockList(let params),
             .followingList(let params),
             .followerList(let params),
             .follow(let params),
             .exitRoomRecommend(let params),
             .inviteFriends(let params),
             .inviteUser(let params),
             .userSearch(let params),
             .requestSmsCode(let params),
             .verifySmsCode(let params),
             .unlockDecoration(let params),
             .updateDecoration(let params),
             .setGameSkill(let params),
             .removeGameSkill(let params),
             .userGameSkills(let params),
             .startGroupChannel(let params),
             .stopGroupChannel(let params),
             .enterGroupChannel(let params),
             .leaveGroupChannel(let params),
             .groupLiveUserList(let params),
             .followersToAddToGroup(let params),
             .addMemberToGroup(let params),
             .groupList(let params),
             .myGroupList(let params),
             .groupNickName(let params),
             .groupListOfHost(let params),
             .groupListOfJoined(let params),
             .groupAppliedUserList(let params),
             .groupMemberList(let params),
             .groupRoomSeatRemove(let params),
             .groupRoomSeatAdd(let params),
             .groupRoomInviteUser(let params),
             .groupInfo(let params),
             .groupRoomInviteFriends(let params),
             .leaveGroup(let params),
             .applyToJoinGroup(let params),
             .handleGroupApply(let params),
             .deleteGroup(let params),
             .roomMuteInfo(let params),
             .unFollow(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
            
        case let .uploadFile(data, ext, mimeType, type):
            let fileData = Moya.MultipartFormData(provider: .data(data), name: "file", fileName: "ios_\(CFAbsoluteTimeGetCurrent()).\(ext)", mimeType: mimeType)
            let extData = Moya.MultipartFormData(provider: .data(ext.data(using: .utf8)!), name: "file_ext")
            let typeData = Moya.MultipartFormData(provider: .data(type.rawValue.data(using: .utf8)!), name: "res_type")
            return .uploadMultipart([extData, typeData, fileData])
        }
    }
    
    var headers: [String : String]? {
        var additionalHeaders = HTTPHeaders.default.dictionary
        additionalHeaders["X-Among-Ua"] = APIService.Config.userAgent
        if let result = Settings.shared.loginResult.value {
            additionalHeaders["X-Uid"] = "\(result.uid)"
        }
        additionalHeaders["X-ACCESS-TOKEN"] = Settings.shared.loginResult.value?.access_token ?? ""
        return additionalHeaders
    }
    
}

extension APIService.AmongChatBackend: CachePolicyGettableType {
    
    var cachePolicy: URLRequest.CachePolicy? {
        return nil
    }
}

extension APIService.AmongChatBackend {
    
    public enum FileType: String {
        case audio
        case video
        case image
        case binary
    }
    
}
