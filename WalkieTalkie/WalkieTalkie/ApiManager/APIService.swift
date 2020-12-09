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

struct APIService {}

extension APIService {
    enum WalkieTalkie {
        case enterRoom(roomName: String)
        case leaveRoom(roomName: String)
    }
}

extension APIService.WalkieTalkie: TargetType {
    var baseURL: URL {
        #if DEBUG
        let url = "https://us-central1-walkietalkie-a6b37.cloudfunctions.net"
        #else
        let url = "https://us-central1-walkietalkie-a6b37.cloudfunctions.net"
        #endif
        return URL(string: url)!
    }
    
    var path: String {
        switch self {
        case .enterRoom(_), .leaveRoom(_):
//            #if DEBUG
//            return "test-app/channels/user/event"
//            #else
            return "app/channels/user/event"
//            #endif
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .enterRoom(_), .leaveRoom(_):
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .enterRoom(let room):
            var baseParams: [String : Any] = [:]
            baseParams["channel"] = room
            baseParams["eventType"] = "enterChannel"
            return .requestParameters(parameters: baseParams, encoding: URLEncoding.queryString)
            
        case .leaveRoom(let room):
            var baseParams: [String : Any] = [:]
            baseParams["channel"] = room
            baseParams["eventType"] = "leaveChannel"
            return .requestParameters(parameters: baseParams, encoding: URLEncoding.queryString)

        }
    }
    
    var headers: [String : String]? {
        var additionalHeaders = HTTPHeaders.default.dictionary
        additionalHeaders["User-Agent"] = APIService.Config.userAgent
        return additionalHeaders
    }
}


