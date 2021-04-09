//
//  JoinRoomable.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol JoinRoomable {
    var contentScrollView: UIScrollView? { get }
    var isRequestingRoom: Bool { get set }
}

struct ParentPageSource {
    let key: String

    static let matchSource = ParentPageSource(key: "match")
    //快速切换
    static let roomSource = ParentPageSource(key: "room")
    
    enum Page: String {
        case none
        case match
        case friends
        case link
        case create
        case create_match ////hottopic
        
        case join_friend_room
        case room //
    }
    
    var page: Page {
        return Page(rawValue: key) ?? .none
    }
    
    var isFromCreatePage: Bool {
        page == ParentPageSource.Page.create || page == ParentPageSource.Page.create_match
    }
    
    init(key: String) {
        self.key = key
    }
    
    init(_ page: Page) {
        self.key = page.rawValue
    }
    
}

struct ParentApiSource {
    let key: String

//    static let matchSource = ParentPageSource(key: "match")
    
    enum Page: String {
        case none
        case join_friend_room
    }
    
    var page: Page {
        return Page(rawValue: key) ?? .none
    }
    
    init(key: String) {
        self.key = key
    }
    
    init(_ page: Page) {
        self.key = page.rawValue
    }
    
}

extension WalkieTalkie.ViewController {
//    struct EnterRoomLogSource {
//
//
//        let key: String
//
//        static let matchSource = EnterRoomLogSource(key: "match")
//        static let friendsSource = EnterRoomLogSource(key: "friends")
//        static let urlSource = EnterRoomLogSource(key: "link")
//        static let creatingSource = EnterRoomLogSource(key: "create")
//        static let creatingMatchSource = EnterRoomLogSource(key: "create_match")
//        //hottopic
//    }
    
//    struct EnterRoomApiSource {
//        let key: String
//
//        static let joinFriendSource = EnterRoomApiSource(key: "join_friend_room")
//    }
}

extension JoinRoomable where Self: ViewController {
    func enterRoom(roomId: String? = nil, topicId: String?, logSource: ParentPageSource? = nil, apiSource: ParentApiSource? = nil) {
        Logger.Action.log(.enter_home_topic, categoryValue: topicId)
        //
        UIApplication.tabBarController?.dismissNotificationBanner()
        
        var topic = topicId
        if roomId == nil {
            topic = topicId ?? AmongChat.Topic.amongus.rawValue
        }
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        
        let completion = { [weak self] in
            self?.contentScrollView?.isUserInteractionEnabled = true
            self?.isRequestingRoom = false
            hudRemoval()
        }
        
        contentScrollView?.isUserInteractionEnabled = false
        isRequestingRoom = true
        Request.enterRoom(roomId: roomId, topicId: topic, source: apiSource?.key)
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
            
                AmongChat.Room.ContainerController.join(room: room, from: self, logSource: logSource) { error in
                    completion()
                    //dismiss
                    UIApplication.tabBarController?.dismissNotificationBanner()
                }

            }, onError: { [weak self] (error) in
                completion()
                cdPrint("error: \(error.localizedDescription)")
                var msg: String {
                    if let error = error as? MsgError {
                        if let codeType = error.codeType, codeType == .needUpgrade {
                            return R.string.localizable.forceUpgradeTip()
                        }
                        return error.localizedDescription
                    } else {
                        return R.string.localizable.amongChatHomeEnterRoomFailed()
                    }
                }
                self?.view.raft.autoShow(.text(msg), userInteractionEnabled: false)
            })
            .disposed(by: bag)

    }
    
    func enterRoom(group: Entity.Group, logSource: ParentPageSource? = nil, apiSource: ParentApiSource? = nil) {
//        Logger.Action.log(.enter_home_topic, categoryValue: topicId)
        //
        UIApplication.tabBarController?.dismissNotificationBanner()
        //
//        var topic = topicId
//        if roomId == nil {
//            topic = topicId ?? AmongChat.Topic.amongus.rawValue
//        }
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        
        let completion = { [weak self] in
            self?.contentScrollView?.isUserInteractionEnabled = true
            self?.isRequestingRoom = false
            hudRemoval()
        }
        
        contentScrollView?.isUserInteractionEnabled = false
        isRequestingRoom = true
        //start or enter
        var requestObservable: Single<Entity.GroupInfo?> {
            if group.uid == Settings.loginUserId {
                //request
                return Request.startChannel(groupId: group.gid)
                    .map { item -> Entity.GroupInfo? in
                        guard let item = item else {
                            return nil
                        }
                        return Entity.GroupInfo(group: item, members: nil, userStatusInt: 1)
                    }
            } else {
                //request
                return Request.enterChannel(groupId: group.gid)
            }
        }
        requestObservable
            .subscribe { [weak self] groupInfo in
                // TODO: - 进入房间
                guard let `self` = self else {
                    return
                }
                guard let groupInfo = groupInfo else {
                    completion()
                    self.view.raft.autoShow(.text(R.string.localizable.amongChatHomeEnterRoomFailed()))
                    return
                }
            
                AmongChat.GroupRoom.ContainerController.join(with: groupInfo, from: self, logSource: logSource) { error in
                    completion()
                    //dismiss
                    UIApplication.tabBarController?.dismissNotificationBanner()
                }

            } onError: { [weak self] (error) in
                completion()
                cdPrint("error: \(error.localizedDescription)")
                var msg: String {
                    if let error = error as? MsgError {
                        if let codeType = error.codeType, codeType == .needUpgrade {
                            return R.string.localizable.forceUpgradeTip()
                        }
                        return error.localizedDescription
                    } else {
                        return R.string.localizable.amongChatHomeEnterRoomFailed()
                    }
                }
                self?.view.raft.autoShow(.text(msg), userInteractionEnabled: false)
            }
            .disposed(by: bag)
//        Request.enterRoom(roomId: roomId, topicId: topic, source: apiSource?.key)
//            .subscribe(onSuccess: { [weak self] (room) in
//                // TODO: - 进入房间
//                guard let `self` = self else {
//                    return
//                }
//                guard let room = room else {
//                    completion()
//                    self.view.raft.autoShow(.text(R.string.localizable.amongChatHomeEnterRoomFailed()))
//                    return
//                }
//
//                AmongChat.GroupRoom.ContainerController.join(room: room, from: self, logSource: logSource) { error in
//                    completion()
//                    //dismiss
//                    UIApplication.tabBarController?.dismissNotificationBanner()
//                }
//
//            }, onError: { [weak self] (error) in
//                completion()
//                cdPrint("error: \(error.localizedDescription)")
//                var msg: String {
//                    if let error = error as? MsgError {
//                        if let codeType = error.codeType, codeType == .needUpgrade {
//                            return R.string.localizable.forceUpgradeTip()
//                        }
//                        return error.localizedDescription
//                    } else {
//                        return R.string.localizable.amongChatHomeEnterRoomFailed()
//                    }
//                }
//                self?.view.raft.autoShow(.text(msg), userInteractionEnabled: false)
//            })
//            .disposed(by: bag)

    }
    
}
