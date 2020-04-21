//
//  URI.Parse.swift
//  Castbox
//
//  Created by ChenDong on 2018/3/22.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation

/// Define URI Domain for other types' extensions
extension URI {
    struct Domain<Base> {
        let base: Base
        init(_ base: Base) {
            self.base = base
        }
    }
}

extension String {
    var uri: URI.Domain<String> {
        return .init(self)
    }
}
/// Add some methods for parsing of basic types such as String 
extension URI.Domain where Base == String {
    
    var id: String? {
        guard var id = self.base.components(separatedBy: "-").last else { return nil }
        if id.hasPrefix("id") {
            let index = id.index(id.startIndex, offsetBy: 2)
            id = String(id[index...])
        }
        return id
    }
    
    var time: Float64 {
        var seconds: Float64 = 0
        let hoursMinsSeconds = self.base.components(separatedBy: ":")
        hoursMinsSeconds.reversed().enumerated().forEach({ (offset, str) in
            if offset == 0 {
                seconds += Float64(str) ?? 0
            } else if offset == 1 {
                seconds += (Float64(str) ?? 0) * 60
            } else if offset == 2 {
                seconds += (Float64(str) ?? 0) * 3600
            }
        })
        
        return seconds
    }
    
    var bool: Bool {
        if let num = Int(self.base) {
            return num != 0
        } else {
            return Bool(self.base) ?? false
        }
    }
}

