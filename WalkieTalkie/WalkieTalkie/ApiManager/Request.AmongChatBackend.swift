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
        NetworkLoggerPlugin(),
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
