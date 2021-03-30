//
//  AmongChat.GroupRoom.ViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwifterSwift
import SwiftyUserDefaults
import AgoraRtcKit
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[AmongChat.GroupRoom.ViewModel]-\(message)")
}

extension AmongChat.GroupRoom {
    
//    enum EndRoomAction {
//        case accountKicked
//        case disconnected
//        case normalClose //true if enter a closed room for listener
//        case tokenError
//        case forbidden //被封
//        //listener
//        case enterClosedRoom
//        case kickout(ChatRoom.KickOutMessage.Role) //被踢出
//        case beBlocked
//    }
    
    
    class ViewModel: AmongChat.Room.ViewModel {
     
//        override static func make(_ room: Entity.Room, _ source: ParentPageSource?) -> ViewModel {
////            guard let shared = self.shared,
////                  shared.room.roomId == room.roomId else {
////                let manager = ViewModel(room: room, source: source)
////                //退出之前房间
////                //                self.shared?.quitRoom()
////                //设置新房间
////                self.shared = manager
////                return manager
////            }
////            return shared
//            return ViewModel(room: room, source: source)
//        }
    }
}
