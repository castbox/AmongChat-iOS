//
//  APIService.Cache.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/19.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya

protocol CachePolicyGettableType {
    var cachePolicy: URLRequest.CachePolicy? { get }
}

final class NetworkCachePolicyPlugin: PluginType {
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let policyGettable = target as? CachePolicyGettableType, let policy = policyGettable.cachePolicy else {
            return request
        }

        var mutableRequest = request
        mutableRequest.cachePolicy = policy

        return mutableRequest
    }
    
}

final class ResponseInterceptPlugin: PluginType {
        
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        
        cdPrint("==\(NSStringFromClass(Self.self))==receive response:\(result)")

        //only continue if result is a failure
        guard case Result.failure(let error) = result else { return }
        
        guard let code = error.response?.statusCode,
              code == 401 else {
            return
        }
        
        cdPrint("==\(NSStringFromClass(Self.self))==catch a 401 error")
    }
    
}
