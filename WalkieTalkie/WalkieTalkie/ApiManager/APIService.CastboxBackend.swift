//
//  APIService.CastboxBackend.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import Alamofire

extension APIService {
    enum CastboxBackend {
        case secret([String : Any])
        case devices([String : Any])
        case pushEvent([String : Any])
    }
}
extension APIService.CastboxBackend: TargetType {
    var baseURL: URL {
        #if DEBUG
        let url = "https://dev.saas.castbox.fm"
        #else
        let url = "https://saas.castbox.fm"
        #endif
        return URL(string: url)!
    }
    
    var path: String {
        switch self {
        case .secret:
            return "auth/api/v1/tokens/provider/secret"
        case .devices:
            return "device/api/v1/devices"
        case .pushEvent:
            return "push/api/v1/push/app/event"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .secret, .devices, .pushEvent:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data(capacity: 10)
    }
    
    var task: Task {
        switch self {
        case .secret(let params), .devices(let params), .pushEvent(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
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
