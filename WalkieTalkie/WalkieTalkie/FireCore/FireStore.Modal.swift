//
//  FireStore.Modal.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension FireStore {
    struct ChannelConfig: Codable {
//        #if DEBUG
//        static let `default` = ChannelConfig(gUserLimit: 2, sSpeakerLimit: 1, sUserLimit: 3, gSpeakerLimit: 1)
//        #else
        static let `default` = ChannelConfig(gUserLimit: 20, sSpeakerLimit: 5, sUserLimit: 50, gSpeakerLimit: 10)
//        #endif
        
        let gUserLimit: Int
        let sSpeakerLimit: Int
        let sUserLimit: Int
        let gSpeakerLimit: Int
        private enum CodingKeys: String, CodingKey {
            case gUserLimit = "g_user_limit"
            case sSpeakerLimit = "s_speaker_limit"
            case sUserLimit = "s_user_limit"
            case gSpeakerLimit = "g_speaker_limit"
        }
        
        func isReachMaxUser(_ room: Room) -> (Bool, Int) {
            if room.isPrivate {
                return (room.user_count >= sUserLimit, sUserLimit)
            } else {
                return (room.user_count >= gUserLimit, gUserLimit)
            }
        }
        
        func isReachMaxSpeaker(_ room: Room) -> Bool {
            if room.isPrivate {
                return room.user_count < sUserLimit
            } else {
                return room.user_count < gUserLimit
            }
        }
    }
}
