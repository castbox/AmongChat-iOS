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
        guard case Result.success(let success) = result else { return }
        
        let code = success.statusCode
        
        guard code == 401,
              target.path != APIService.AmongChatBackend.login([:]).path,
              Settings.loginUserId != nil else {
            return
        }
        
        cdPrint("==\(NSStringFromClass(Self.self))==catch a 401 error")
        
        Settings.shared.clearAll()
        (UIApplication.shared.delegate as! AppDelegate).setupInitialView()
        
        let messageFromResponse: ((Response) -> String?) = { response in
            
            guard let json = try? response.mapJSON() as? [String : AnyObject],
                  let code = json["code"] as? Int else {
                return nil
            }
            
            let message: String?
            
            switch code {
            case 3, 4: //account suspended, device suspened
                message = R.string.localizable.userLoginBannedTip()
            case 6: //logged in another device
                message = R.string.localizable.userLoginKickedTip()
            default:
                message = nil
            }
            
            return message
            
        }
        
        if let msg = messageFromResponse(success) {
            UIApplication.topViewController()?.view.raft.autoShow(.text(msg), interval: 3, userInteractionEnabled: false)
        }
        
    }
    
}
