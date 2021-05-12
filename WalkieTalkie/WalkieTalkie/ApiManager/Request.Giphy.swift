//
//  Request.Giphy.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 11/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import RxSwift

extension Request {
    static let giphyProvider = MoyaProvider<APIService.Giphy>(plugins: [
        NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(formatter: NetworkLoggerPlugin.Configuration.Formatter(), output: NetworkLoggerPlugin.Configuration.defaultOutput, logOptions: .verbose)),
        NetworkCachePolicyPlugin(),
        ResponseInterceptPlugin()
    ])
}
/**
 api_key: string(required)    YOUR_API_KEY    GIPHY API Key.
 limit: integer (int32)    20    The maximum number of objects to return. (Default: “25”)
 offset: integer (int32)    5    Specifies the starting position of the results. Default: “0” Maximum: “4999”
 rating: string    g    Filters results by specified rating. Acceptable values include g, pg, pg-13, r. If you do not specify a rating, you will receive results from all possible ratings.
 random_id: string    e826c9fc5c929e0d6c6d423841a282aa    An ID/proxy for a specific user.
 
 */

extension Request {
    static func gifTreading(_ limit: Int = 30, offset: Int = 0, rating: String = "g") -> Single<[Giphy.GPHMedia]?> {
        let params: [String: Any] = [
            "api_key": Constants.giphyApiKey,
            "limit": limit,
            "offset": offset,
            "rating": rating
        ]
        return giphyProvider.rx.request(.gifTreading(params))
            .mapJSON()
            .mapToDataKeyListValue()
            .mapTo([Giphy.GPHMedia].self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func gifSearch(key: String, limit: Int = 30, offset: Int = 0, rating: String = "g") -> Single<[Giphy.GPHMedia]?> {
        let params: [String: Any] = [
            "api_key": Constants.giphyApiKey,
            "q": key,
            "limit": limit,
            "offset": offset,
            "rating": rating
        ]
        return giphyProvider.rx.request(.gifSearch(params))
            .mapJSON()
            .mapToDataKeyListValue()
            .mapTo([Giphy.GPHMedia].self)
            .observeOn(MainScheduler.asyncInstance)
    }
}
