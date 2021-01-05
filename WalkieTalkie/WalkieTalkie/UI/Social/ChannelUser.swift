//
//  ChannelUser.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

struct ChannelUser: Codable, DefaultsSerializable {
    enum Status: String, Codable, DefaultsSerializable {
        case connected
        case talking
        case blocked
        case muted
        case droped //已下麦
        

        static var _defaults: DefaultsRawRepresentableBridge<Status> {
            return DefaultsRawRepresentableBridge<Status>()
        }
        
        static var _defaultsArray: DefaultsRawRepresentableArrayBridge<[Status]> {
            return DefaultsRawRepresentableArrayBridge<[Status]>()
        }
    }
    
    let uid: String
    let name: String
    let avatar: String
//    let name: String
    let robloxName: String?
    let seatNo: Int
    
    let prefix: String
    let iconColor: String
    var status: Status
    var isMuted: Bool
    
    private static let colors: [String] = [
        "F5CEC7",
        "FFB384",
        "FFC98B",
        "C6C09C",
        "BD9DDE"
    ]
    
    private static let tag: [String] = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    ]
    
    static func randomUser(uid: UInt) -> ChannelUser {
        return ChannelUser(uid: String(uid), name: "User - \(uid)", avatar: "", robloxName: nil, seatNo: 0, prefix: tag.randomItem() ?? "A", iconColor: colors.randomItem() ?? "F5CEC7", status: .connected, isMuted: false)
    }
}
