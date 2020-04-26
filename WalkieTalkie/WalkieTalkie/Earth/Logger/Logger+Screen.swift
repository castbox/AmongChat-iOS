//
//  Logger+Screen.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/21.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension Logger {
    
    struct Screen: LoggerPath {
        
        enum Node {
            
            // 使用枚举使得可以在编译期发现打点问题
            enum Start: String {
                case ios_ignore //
                case channel
                case settings
                case premium
                case tutorial
                case secret_channel_create_pop_imp
            }
            
            case start(Start)
        }
        
        let nodes: [Node]
                
        func validate(node: Logger.Screen.Node, after nodes: [Logger.Screen.Node]) -> (valid: Bool, end: Bool) {

            guard let _ = nodes.last else {
                
                switch node {
                case .start:
                    return (true, true)
                }
            }
            
            return (false, false)
        }
        
        func log() {
            
            guard let node = self.nodes.first else { return }
            switch node {
            case .start(let start):
                GuruAnalytics.log(event: "screen",
                              category: "screen",
                              name: start.rawValue,
                              value: nil)
            }
        }
        
        static func log(_ country: Node.Start) {
            Logger.Screen.start(with: .start(country))
        }
    }
}
