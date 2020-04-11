//
//  Cuddle.swift
//  Moya-Cuddle
//
//  Created by Wilson on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import Moya
import Alamofire
//import CastboxNetwork

extension ApiManager {
    enum WalkieTalkie {
        case enterRoom
    }
}

extension ApiManager.WalkieTalkie: TargetType {
    var baseURL: URL {
        switch self {
        default:
            return URL(string: ApiManager.Config.host)!
        }
    }
    
    var path: String {
        switch self {
        case .enterRoom:
            return "/app/channels/event"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .enterRoom:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
//        case .enterRoom(let params):
//            return .requestData(try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted))
        default:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        var additionalHeaders = HTTPHeaders.default.dictionary
        additionalHeaders["User-Agent"] = ApiManager.Config.userAgent
        return additionalHeaders
    }
}


