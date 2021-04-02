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
    
    
    class ViewModel: AmongChat.BaseRoomViewModel {
        var group: Entity.GroupRoom {
            roomReplay.value as! Entity.GroupRoom
        }
        
        
//        override init(room: RoomInfoable, source: ParentPageSource?) {
//            
//        }
        
//        init(room: RoomInfoable, source: ParentPageSource?) {
//
//        }
        
        
        func requestLeaveChannel() -> Single<Bool> {
//            Logger.Action.log(.room_leave_clk, categoryValue: room.topicId, nil, stayDuration)
//            mManager.leaveChannel()
//            imViewModel.leaveChannel()
            quitServices()
//            ViewModel.shared = nil
//            state = .disconnected
//            UIApplication.shared.isIdleTimerDisabled = false
            //
            if group.loginUserIsAdmin {
                return Request.stopChannel(groupId: group.gid)
            }
            return Request.leaveChannel(groupId: group.gid)
        }

    }
}
