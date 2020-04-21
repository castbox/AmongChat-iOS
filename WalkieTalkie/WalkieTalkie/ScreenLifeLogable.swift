//
//  ScreenLifeLogable.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/21.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

protocol ScreenLifeLogable {
    var screenLifeStartTime: Date { get set }
    var screenName: Logger.Screen.Node.Start { get }
}

extension ScreenLifeLogable {
    var screenLifeDuration: Int64 {
        return Int64(Date().timeIntervalSince1970 - screenLifeStartTime.timeIntervalSince1970)
    }
    
    func loggerScreenDuration(withType screen: Logger.Screen.Node.Start, duration: Int64? = nil) {
        guard screen == .ios_ignore else {
            return
        }
        let duration = duration ?? screenLifeDuration
        guard duration > 1 else {
            return
        }
        Logger.PageShow.log(.screen, .screen_life, screen.rawValue, duration)
    }
    
    func loggerScreenDuration(withName screen: String? = nil, duration: Int64? = nil) {
        if screen == nil && screenName == .ios_ignore {
            return
        }
        let duration = duration ?? screenLifeDuration
        guard duration > 1 else {
            return
        }
        Logger.PageShow.log(.screen, .screen_life, screen ?? screenName.rawValue, duration)
    }
    
    func loggerScreenShow(_ screen: Logger.Screen.Node.Start? = nil) {
        let result = screen ?? screenName
        guard result != .ios_ignore else {
            return
        }
        Logger.Screen.log(result)
    }
}
