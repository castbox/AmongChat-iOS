//
//  Routes.Constructor.swift
//  Castbox
//
//  Created by lazy on 2019/3/27.
//  Copyright © 2019年 Guru. All rights reserved.
//

import Foundation

extension Routes {
    
    static func play(with time: String?, _ eid: Int) -> String {
        if let t = time {
            return "https://www.cuddlelive.com/vd/\(eid)?_t=\(t)"
        } else {
            return "https://www.cuddlelive.com/vd/\(eid)"
        }
    }
    
    static func link(_ text: String) -> String {
        return text.hasPrefix("http") ? text: "https://\(text)"
    }
    
    static func testFeedLink() -> String {
        return "/feeds/PhdgThJjN"
    }
}

