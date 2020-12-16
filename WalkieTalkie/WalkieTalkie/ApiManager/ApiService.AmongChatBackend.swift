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
        case updateRoomInfo([String : Any])
    }
}
extension APIService.AmongChatBackend: TargetType {
    var baseURL: URL {
//        #if DEBUG
//        let url = "https://dev.saas.castbox.fm"
//        #else
        let url = "https://saas.castbox.fm"
//        #endif
        return URL(string: url)!
    }
    
    var path: String {
        switch self {
        case .updateRoomInfo:
            return "/api/v1/rooms/update"
        }
    }
    
    var method: Moya.Method {
        switch self {
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
        case .updateRoomInfo(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
//        case .secret(let params), .devices(let params), .pushEvent(let params):
//            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        var additionalHeaders = HTTPHeaders.default.dictionary
        additionalHeaders["User-Agent"] = APIService.Config.userAgent
        additionalHeaders["X-APP-ID"] = "walkietalkie"
        additionalHeaders["X-ACCESS-TOKEN"] = Settings.shared.loginResult.value?.token ?? ""
        return additionalHeaders
    }
    
}

