//
//  Request.AmongChatBackend.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Moya
import RxSwift

extension Request {
    static let amongchatProvider = MoyaProvider<APIService.AmongChatBackend>(plugins: [
        NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(formatter: NetworkLoggerPlugin.Configuration.Formatter(), output: NetworkLoggerPlugin.Configuration.defaultOutput, logOptions: .verbose)),
    ])
}


extension Request {
    
    static func login(via provider: Entity.LoginProvider, token: String? = nil, secret: String? = nil, transferFrom uid: String? = nil, clientType: String = "ios") -> Single<Entity.LoginResult?> {
        
        var paras = ["provider": provider.rawValue]
        paras["client_type"] = clientType
        
        if let token = token { paras["token"] = token }
        if let secret = secret { paras["secret"] = secret }
        if let uid = uid { paras["uid"] = uid }
        
        return amongchatProvider.rx.request(.login(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.LoginResult.self)
    }
    
    static func enterRoom(roomId: String, topicId: String) -> Single<Entity.Room?> {
        
        var paras = [String : Any]()
        paras["room_id"] = roomId
        paras["topic_id"] = topicId
        
        return amongchatProvider.rx.request(.enteryRoom(paras))
            .mapJSON()
            .map { item -> [String : AnyObject] in
                guard let json = item as? [String: AnyObject],
                 let data = json["data"] as? [String: AnyObject],
                 let roomData = data["room"] as? [String : AnyObject] else {
                    return [:]
                }
                return roomData
            }
            .mapTo(Entity.Room.self)
    }
    
    static func createRoom(_ room: Entity.RoomProto) -> Single<Entity.Room?> {
        
        guard let params = room.dictionary else {
            return Observable.just(nil).asSingle()
        }
        
        return amongchatProvider.rx.request(.createRoom(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .map { item -> [String : AnyObject] in
                guard let roomData = item["room"] as? [String : AnyObject] else {
                    return [:]
                }
                return roomData
            }
            .mapTo(Entity.Room.self)
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func updateRoomInfo(room: Entity.Room?) -> Single<Bool> {
        guard let params = room?.dictionary else {
            return Observable<Bool>.empty().asSingle()
        }
        return amongchatProvider.rx.request(.updateRoomInfo(params))
            .mapJSON()
            .map { (jsonAny) -> Bool in
                guard let jsonDict = jsonAny as? [String : Any],
                    jsonDict.count == 0 else { return false }
                return true
        }
    }

}
