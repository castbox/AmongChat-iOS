//
//  AudioType.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

enum AudioType: String, CaseIterable {
    case begin
    case end
    case call
}

extension AudioType {
    
    var name: String {
        switch self {
        case .begin:
            return "cbegin"
        default:
            return rawValue
        }
    }
    
    var type: String {
        switch self {
        case .end, .begin:
            return ".mp3"
        case .call:
            return ".m4a"
        }
    }
    
    var path: String? {
        return Bundle.main.path(forResource: name, ofType: type)
    }
    
    var index: Int32 {
        switch self {
        case .end:
            return 1
        case .begin:
            return 2
        case .call:
            return 3
        }
    }
}
