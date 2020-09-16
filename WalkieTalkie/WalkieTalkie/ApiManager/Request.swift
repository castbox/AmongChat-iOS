//
//  Request.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import RxSwift

struct Request {
    static let dataProvider = MoyaProvider<APIService.WalkieTalkie>(plugins: [
        NetworkLoggerPlugin(),
    ])
    static let castboxProvider = MoyaProvider<APIService.CastboxBackend>(plugins: [
        NetworkLoggerPlugin(),
    ])
}

extension Request {
    static func reportEnterRoom(_ room: String) -> Single<Entity.Channel?> {
        return dataProvider.rx.request(.enterRoom(roomName: room))
            .mapJSON()
            .map({ (json) -> Entity.Channel? in
                var channel: Entity.Channel?
                decoderCatcher {
                    channel = try JSONDecoder().decodeAnyData(Entity.Channel.self, from: json) as Entity.Channel
                }
                return channel
            })
    }
    
    static func reportLeaveRoom(_ room: String) -> Single<Entity.Channel?> {
        return dataProvider.rx.request(.leaveRoom(roomName: room))
            .mapJSON()
            .map({ (json) -> Entity.Channel? in
                var channel: Entity.Channel?
                decoderCatcher {
                    channel = try JSONDecoder().decodeAnyData(Entity.Channel.self, from: json) as Entity.Channel
                }
                return channel
            })
    }
    
    static func login(deviceId: String) -> Single<Entity.LoginResult?> {
        typealias LoginResult = Entity.LoginResult
        var params: [String : Any] = [:]
        params["secret"] = deviceId
        return castboxProvider.rx.request(.secret(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.LoginResult.self)
    }
    
    static func devices(params: [String : Any]) -> Single<Bool> {
        return castboxProvider.rx.request(.devices(params))
            .mapJSON()
            .map { (jsonAny) -> Bool in
                guard let jsonDict = jsonAny as? [String : Any],
                    jsonDict.count == 0 else { return false }
                return true
        }
    }
    
    enum PushEventType: String {
        case DeviceOpen
        case DeviceReceive
    }
    
    static func pushEvent(_ type: PushEventType, notiUserInfo: [AnyHashable : Any]) -> Single<Bool> {
        
        guard let serverParams = notiUserInfo["serverParams"] else {
            return Observable<Bool>.just(true).asSingle()
        }
        
        var params: [String : Any] = [:]
        let deviceInfo = Constants.deviceInfo()
        params["deviceData"] = deviceInfo
        params["eventType"] = type.rawValue
        params["serverParams"] = serverParams

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        params["appEventTime"] = dateFormatter.string(from: Date())
        
        return castboxProvider.rx.request(.pushEvent(params))
            .mapJSON()
            .map { (jsonAny) -> Bool in
                guard let jsonDict = jsonAny as? [String : Any],
                    jsonDict.count == 0 else { return false }
                return true
        }
    }

}
