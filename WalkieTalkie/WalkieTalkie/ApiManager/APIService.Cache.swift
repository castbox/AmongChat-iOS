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
