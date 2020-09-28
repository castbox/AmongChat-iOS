//
//  UserDefaults+Extension.swift
//  WalkieTalkie
//
//  Created by mayue on 2020/9/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import SwiftyUserDefaults

/// app group共享user defaults
public var SharedDefaults = DefaultsAdapter(defaults: UserDefaults(suiteName: "group.com.talkie.walkie")!, keyStore: DefaultsKeys())

extension DefaultsKeys {
    
    var topPublicChannelsKey: DefaultsKey<[[String : Any]]> {
        .init("com.talkie.walkie.top.public.channels", defaultValue: [])
    }
    
    var loginResultTokenKey: DefaultsKey<String?> {
        .init("lgoin.result.token", defaultValue: nil)
    }
}
