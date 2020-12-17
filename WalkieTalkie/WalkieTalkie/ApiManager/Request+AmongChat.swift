//
//  Request+AmongChat.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift

extension Request {
    
    static func login(via provider: Entity.LoginProvider, token: String? = nil, secret: String? = nil, transferFrom uid: String? = nil, clientType: String = "ios") -> Single<Entity.LoginResult?> {
        
        var paras = ["provider": provider.rawValue]
        paras["client_type"] = clientType
        
        if let token = token { paras["token"] = token }
        if let secret = secret { paras["secret"] = secret }
        if let uid = uid { paras["uid"] = uid }
        
        return authProvider.rx.request(.login(paras))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.LoginResult.self)
    }
    
//    static func createRoom(_ room: Entity.Room) -> Single<Entity.Room> {
//        
//        let params = [String : Any]()
//        
//        return authProvider.rx.request(.createRoom(params))
//            .mapJSON()
//    }
    
}
