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
        case summary([String : Any])
        case profile
        case updateProfile([String : Any])
        case logout
    }
}
extension APIService.AmongChatBackend: TargetType {
    var baseURL: URL {
        #if DEBUG
        let url = "https://dev.api.among.chat"
        #else
        let url = "https://api.among.chat"
        #endif
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
        case .profile:
            return"/account/profile"
        case .updateProfile:
            return "/account/profile"
        case .logout:
            return "auth/logout"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login, .createRoom, .updateNickName, .updateRoomInfo, .updateProfile, .logout:
            return .post
        case .summary, .enteryRoom, .heartBeating, .rtmToken, .rtcToken, .profile, .leaveRoom, .roomInfo:
            return .get
        //        case .updateRoomInfo:
        //            return .put
        //        case .secret, .devices, .pushEvent:
        //            return .post
        }
    }
    
    var sampleData: Data {
        return Data(capacity: 10)
    }
    
    var task: Task {
        switch self {
        case .enteryRoom(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
            
        case .profile, .logout:
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
            
        case .createRoom(let params),
             .updateProfile(let params),
             .updateRoomInfo(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .login(let params),
             .summary(let params),
             .updateNickName(let params),
             .heartBeating(let params),
             .roomInfo(let params),
             .rtcToken(let params),
             .rtmToken(let params),
             .leaveRoom(let params):
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

