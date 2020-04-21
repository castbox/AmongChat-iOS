//
//  AudioType.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

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
//                    let soundId: Int32 = 1
//        //            let filePath = "your filepath"
//
//                    // 可以加载多个音效
//
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
