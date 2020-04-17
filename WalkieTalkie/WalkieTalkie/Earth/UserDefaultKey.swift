//
//  UserDefaultKey.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
    static let channelName = DefaultsKey<String>.init("channelName", defaultValue: "WELCOME")
}
