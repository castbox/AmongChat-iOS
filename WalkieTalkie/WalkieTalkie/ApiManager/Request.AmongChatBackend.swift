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
