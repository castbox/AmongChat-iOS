//
//  Countable.swift
//  Castbox
//
//  Created by lazy on 2018/11/26.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation

protocol Countable {
    
    associatedtype T
    
    func negative() -> T
}
