//
//  JoinRoomable.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

protocol JoinRoomable {
    var contentScrollView: UIScrollView? { get }
}

extension JoinRoomable where Self: ViewController {
    func enterRoom(roomId: String? = nil, topicId: String?, source: String = "match") {
        Logger.Action.log(.enter_home_topic, categoryValue: topicId)
        
        var topic = topicId
        if roomId == nil {
            topic = topicId ?? AmongChat.Topic.amongus.rawValue
        }
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        
        let completion = { [weak self] in
            self?.contentScrollView?.isUserInteractionEnabled = true
            hudRemoval()
        }
        
        contentScrollView?.isUserInteractionEnabled = false
        Request.enterRoom(roomId: roomId, topicId: topic)
            .subscribe(onSuccess: { [weak self] (room) in
                // TODO: - 进入房间
                guard let `self` = self else {
                    return
                }
                guard let room = room else {
                    completion()
                    self.view.raft.autoShow(.text(R.string.localizable.amongChatHomeEnterRoomFailed()))
                    return
                }
                
                AmongChat.Room.ViewController.join(room: room, from: self, source: source) { error in
                    completion()
                }

            }, onError: { [weak self] (error) in
                completion()
                cdPrint("error: \(error.localizedDescription)")
                var msg: String {
                    if let error = error as? MsgError,
                       error.codeType != nil {
                        return error.localizedDescription
                    } else {
                        return R.string.localizable.amongChatHomeEnterRoomFailed()
                    }
                }
                self?.view.raft.autoShow(.text(msg), userInteractionEnabled: false)
            })
            .disposed(by: bag)

    }
    
}
