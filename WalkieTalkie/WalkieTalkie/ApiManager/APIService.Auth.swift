//
//  APIService.Auth.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import Alamofire

extension APIService {
    enum Auth {
        /**
         "roomId": "hdDVPJZc",
         "topicId": "amongus",
         "state": "public"
         */
        case roomUpdate([String: Any])
        case updateNickName([String: Any])
        case heartBeating([String: Any])
        case login([String : Any])
        case createRoom([String : Any])
    }
}

extension APIService.Auth: TargetType {
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
        case .roomUpdate:
            return "/api/v1/rooms/update"
        case .updateNickName:
            return "/api/v1/rooms/nickname"
        case .heartBeating:
            return "/api/v1/rooms/heartbeat"
        case .login:
            return "/auth/login"
        case .createRoom:
            return "/api/v1/rooms/create"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login, .createRoom, .roomUpdate, .updateNickName:
            return .post
        case .heartBeating:
            return .get
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
        case .updateNickName(let params), .heartBeating(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .createRoom(let params),
             .roomUpdate(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
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
