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
    static func reportEnterRoom() -> Single<Any> {
        return dataProvider.rx.request(.enterRoom)
            .mapJSON()
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
    
    enum PushEventType {
        case DeviceOpen
        case DeviceReceive
    }
    
    static func pushEvent(_ type: PushEventType, notiUserInfo: [AnyHashable : Any]) -> Single<Bool> {
        
        guard let _ = notiUserInfo["gcm.message_id"] else {
            return Observable<Bool>.just(true).asSingle()
        }
        
        var params: [String : Any] = [:]
        let deviceInfo = Constants.deviceInfo()
        params["deviceData"] = deviceInfo
        params["eventType"] = "\(type)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        params["appEventTime"] = dateFormatter.string(from: Date())
        
        if let pushId = notiUserInfo["pushEventId"] {
            params["pushEventId"] = pushId
        }
        
        if let taskName = notiUserInfo["taskName"] {
            params["taskName"] = taskName
        }
        
        if let serverPushTime = notiUserInfo["serverPushTime"] {
            params["serverPushTime"] = serverPushTime
        }
        
        return castboxProvider.rx.request(.pushEvent(params))
            .mapJSON()
            .map { (jsonAny) -> Bool in
                guard let jsonDict = jsonAny as? [String : Any],
                    jsonDict.count == 0 else { return false }
                return true
        }
    }

}
