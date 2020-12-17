//
//  Entity.Room.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension Entity {
    
    enum RoomPublicType: String, Codable {
        case `public`
        case `private`
        
        private enum CodingKeys: String, CodingKey {
            case `public` = "PUBLIC"
            case `private` = "PRIVATE"
        }
    }
    
    enum AmongUsZone: Int, Codable {
        case northAmercia
        case asia
        case europe
    }
    
    //房间类型
    struct Room: Codable {
        
        var amongUsCode: String?
        var amongUsZone: AmongUsZone?
        var note: String?
        let roomId: String
        
        let roomUserList: [RoomUser]
        var state: RoomPublicType
        var topicId: AmongChat.Topic
        let topicName: String
        
        var isValidAmongConfig: Bool {
            guard topicId == .amongus,
                  let code = amongUsCode,
                  amongUsZone != nil else {
                return false
            }
            return !code.isEmpty
        }
    }
    
    struct RoomUser: Codable, DefaultsSerializable {
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
        
        let uid: Int
        let name: String?
        let pictureUrl: String
        let seatNo: Int
        var status: Status?
        var isMuted: Bool?
        let robloxName: String?
        
//<<<<<<< HEAD
        var isMutedValue: Bool {
            return isMuted ?? false
        }
//=======
//        let prefix: String?
//        let iconColor: String?
//        var status: Status = .connected
//        var isMuted: Bool = false
//        
//        private static let colors: [String] = [
//            "F5CEC7",
//            "FFB384",
//            "FFC98B",
//            "C6C09C",
//            "BD9DDE"
//        ]
//        
//        private static let tag: [String] = [
//            "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
//        ]
//>>>>>>> 97a9b8dd5f432058fec15c361923f9fedde73d4b
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case name
            case pictureUrl = "picture_url"
            case seatNo
            case status
            case isMuted = "is_muted"
            case robloxName = "roblox_name"
        }
    }
}

extension Entity.AmongUsZone {
    var title: String {
        switch self {
        case .northAmercia:
            return "North America"
        case .asia:
            return "Asia"
        case .europe:
            return "Europe"
        }
    }
}
