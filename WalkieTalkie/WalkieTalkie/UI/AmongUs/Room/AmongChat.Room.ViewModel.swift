//
//  AmongChat.Room.ViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension AmongChat.Room {
    class ViewModel {
        let roomReplay: BehaviorRelay<Entity.Room>
        let bag = DisposeBag()
        
        var room: Entity.Room {
            roomReplay.value
        }
        
        init(room: Entity.Room) {
//            self.room = room
            roomReplay = BehaviorRelay(value: room)
        }
        
        func changePublicType() {
            let publicType: Entity.RoomPublicType = room.state == .private ? .public : .private
            var room = self.room
            room.state = publicType
            //update
            updateRoomInfo(room)
        }
        
        func update(nickName: String) {
            var room = self.room
//            room.isValidAmongConfig = publicType
            //update
            updateRoomInfo(room)
        }
        
        func update(notes: String) {
            var room = self.room
//            room.isValidAmongConfig = publicType
            //update
            updateRoomInfo(room)
        }
        
        func updateAmong(code: String, aera: Int) {
            
        }
        
        func updateRoomInfo(_ room: Entity.Room) {
            //update
            Request.updateRoomInfo(room: room)
                .filter { $0 }
                .map { _ -> Entity.Room in
                    return room
                }
                .catchErrorJustReturn(self.room)
                .asObservable()
                .bind(to: roomReplay)
                .disposed(by: bag)
        }
    }
}
