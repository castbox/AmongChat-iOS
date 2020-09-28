//
//  ApiService.swift
//  WalkieTalkieWidgetExtension
//
//  Created by mayue on 2020/9/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import SwiftyUserDefaults
import ObjectMapper
import RxSwift

struct Network {
    enum APIService {
        case topChannels(language: String?, limit: Int)
    }
}

extension Network.APIService: TargetType {
    var baseURL: URL {
        let url = "https://us-central1-walkietalkie-a6b37.cloudfunctions.net"
        return URL(string: url)!
    }
    
    var path: String {
        switch self {
        case .topChannels(_, _):
            return "app/channels/top"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .topChannels(_, _):
            return .get
        }
    }
    
    var sampleData: Data {
        return Data(capacity: 10)
    }
    
    var task: Task {
        switch self {
        case .topChannels(let lan, let limit):
            var params = [String : Any]()
            if let lan = lan,
                !lan.isEmpty {
                params["lang"] = lan
            }
            if limit > 0 {
                params["size"] = limit
            }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        var additionalHeaders = HTTPHeaders.default.dictionary
        additionalHeaders["X-APP-ID"] = "walkietalkie"
        additionalHeaders["X-ACCESS-TOKEN"] = SharedDefaults[\.loginResultTokenKey] ?? ""
        return additionalHeaders
    }

}

extension Network {
    struct Request {
        static let provider = MoyaProvider<APIService>()
    }
}

extension Network { struct Entity {} }

extension Network.Entity {
    
    struct Channel: ImmutableMappable {
        
        let name: String
        let userCount: Int
        
        init(map: Map) throws {
            name = try map.value("name")
            userCount = try map.value("userCount")
        }
        
        func mapping(map: Map) {
            name >>> map["name"]
            userCount >>> map["userCount"]
        }
        
        static var defaultTopChannels: [Channel] {
            
            let mapper = Mapper<Channel>()
            let cachedDictArray: [[String : Any]] = SharedDefaults[\.topPublicChannelsKey]
            let channels = cachedDictArray.compactMap { mapper.map(JSON: $0) }
            
            if channels.count > 0 {
                return channels
            } else {
                return [ ["name" : "Welcome".uppercased(), "userCount" : 5] ]
                    .compactMap { mapper.map(JSON: $0) }
            }
        }
        
        static func updateDefaultTopChannels(_ channels: [Channel]) {
            let dictArray = channels.map { $0.toJSON() }
            if dictArray.count > 0 {
                SharedDefaults[\.topPublicChannelsKey] = dictArray
            }
        }
    }
}

extension Network.Entity.Channel: Hashable { }

extension Network.Request {
    static func fetchTopChannels() -> Single<[Network.Entity.Channel]> {
        return provider.rx.request(.topChannels(language: nil, limit: 2))
            .mapJSON()
            .map { (jsonAny) -> [Network.Entity.Channel] in
                guard let dictArray = jsonAny as? [[String : Any]] else {
                    return []
                }

                let mapper = Mapper<Network.Entity.Channel>()
                return dictArray.compactMap { mapper.map(JSON: $0) }
        }
    }
}
