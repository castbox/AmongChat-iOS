//
//  Reachability.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/21.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Alamofire

class Reachability {
    static let shared = Reachability()
    //初始化
    var canReachable: Bool = false
    
    init() {
        let reachability = NetworkReachabilityManager.default
        reachability?.startListening { [weak self] status in
            switch status {
            case .notReachable, .unknown:
                self?.canReachable = false
            default:
                self?.canReachable = true
            }
        }
    }
}
