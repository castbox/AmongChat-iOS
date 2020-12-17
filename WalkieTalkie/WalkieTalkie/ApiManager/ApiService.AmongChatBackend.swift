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
        case updateRoomInfo([String : Any])
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
        case .createRoom:
            return "/api/v1/rooms/create"
        case .enteryRoom:
            return "/api/v1/rooms/enter"
        case .updateRoomInfo:
            return "/api/v1/rooms/update"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login, .createRoom:
            return .post
        case .enteryRoom:
            return .get
        case .updateRoomInfo:
            return .put
//        case .secret, .devices, .pushEvent:
//            return .post
        }
    }
    
    var sampleData: Data {
        return Data(capacity: 10)
    }
    
    var task: Task {
        switch self {
        case .login(let params):
            var baseParams = params
            baseParams["box_token"] = 1
            return .requestParameters(parameters: baseParams, encoding: URLEncoding.queryString)
            
        case .createRoom(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
            
        case .enteryRoom(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.default)

        case .updateRoomInfo(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
//        case .secret(let params), .devices(let params), .pushEvent(let params):
//            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
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

