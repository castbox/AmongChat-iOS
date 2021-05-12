//
//  APIService.Giphy.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 11/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import Alamofire

extension APIService {
    enum Giphy {
        case gifTreading([String: Any])
        case gifSearch([String: Any])
    }
}

extension APIService.Giphy: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.giphy.com")!
    }
    
    var path: String {
        switch self {
        case .gifTreading:
            return "/v1/gifs/trending"
        case .gifSearch:
            return "/v1/gifs/search"
        }
    }
    
    var method: Moya.Method {
        switch self {
        default:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .gifSearch(let params),
             .gifTreading(let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        var additionalHeaders = HTTPHeaders.default.dictionary
//        additionalHeaders["User-Agent"] = APIService.Config.userAgent
        return additionalHeaders
    }
}


