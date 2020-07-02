//
//  Entity.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

struct Entity {
    
}

extension Entity {
    struct LoginResult: Codable {
        let uid: String
        let token: String
        let newUser: Bool
    }
}
