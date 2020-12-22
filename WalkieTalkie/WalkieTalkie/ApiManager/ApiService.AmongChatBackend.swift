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
        case rtcToken([String: Any])
        case rtmToken([String: Any])
        case leaveRoom([String: Any])
        case roomInfo([String: Any])
        case updateRoomInfo([String : Any])
        case kickUsers([String : Any])
        case summary([String : Any])
        case roomNickName([String: Any])
        case profile
        case updateProfile([String : Any])
        case defaultAvatars([String : Any])
        case firebaseToken([String: Any])
        case unlockAvatar([String : Any])
        case sensitiveWords
        case updateDevice([String: Any])
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
        case .rtcToken:
            return "/live/room/token"
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
            return"/account/profile"
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
             .logout:
            return .post
            
        case .summary,
             .enteryRoom,
             .heartBeating,
             .rtmToken,
             .rtcToken,
             .profile,
             .leaveRoom,
             .defaultAvatars,
             .roomInfo,
             .sensitiveWords,
            .firebaseToken:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data(capacity: 10)
    }
    
    var task: Task {
        switch self {
        case .enteryRoom(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
            
        case .profile,
             .defaultAvatars,
             .logout,
             .sensitiveWords:
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
            
        case .createRoom(let params),
             .updateProfile(let params),
             .updateRoomInfo(let params),
             .updateDevice(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .login(let params),
             .summary(let params),
             .updateNickName(let params),
             .heartBeating(let params),
             .roomInfo(let params),
             .rtcToken(let params),
             .rtmToken(let params),
             .leaveRoom(let params),
             .kickUsers(let params),
             .roomNickName(let params),
             .defaultAvatars(let params),
             .unlockAvatar(let params),
             .firebaseToken(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
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
