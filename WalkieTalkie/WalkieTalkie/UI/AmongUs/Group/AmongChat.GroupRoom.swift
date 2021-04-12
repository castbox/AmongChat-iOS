//
//  AmongChat.GroupRoom.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 31/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults

extension AmongChat {
    struct GroupRoom {
        
    }
}

extension AmongChat.GroupRoom {
    class ContainerController: WalkieTalkie.ViewController, GestureBackable {
        var isEnableScreenEdgeGesture: Bool = false
        
        var groupInfo: Entity.GroupInfo!
        var roomViewController: AmongChat.GroupRoom.ViewController?
        var broadcasterPictureURL: String?
        var broadcasterName: String?
        var enterRoomErrorHandler: (() -> Void)?
        var previousRoomInfo: Entity.Group?
        
        var logSource: ParentPageSource?
        var removeLoadingHandler: CallBack? = nil

//        var fromSource: String?
        
//        var isRoomClosed: Bool {
//            return listenerViewController?.dataManager.isRoomClosed ?? true
//        }
        
//        override var hidesNavigationBar: Bool {
//            return true
//        }
        
//        override var preferredStatusBarStyle: UIStatusBarStyle {
//            return .lightContent
//        }
        
        //Defaults[\.testGroup] = group.asString
        static func join(with group: Entity.Group, from controller: UIViewController, logSource: ParentPageSource? = nil, completionHandler: ((Error?) -> Void)? = nil) {
            join(with: Entity.GroupInfo(group: group, members: nil, userStatusInt: 1), from: controller)
        }
        
        static func join(with groupInfo: Entity.GroupInfo, from controller: UIViewController, logSource: ParentPageSource? = nil, completionHandler: ((Error?) -> Void)? = nil) {
            controller.checkMicroPermission { [weak controller] in
                guard let controller = controller else {
                    return
                }
                let vc = AmongChat.GroupRoom.ContainerController(with: groupInfo, logSource: logSource)
                controller.navigationController?.pushViewController(vc, completion: { [weak controller] in
                    guard let ancient = controller,
                          (ancient is AmongChat.CreateRoom.ViewController || ancient is AmongChat.GroupRoom.ViewController) else { return }
                    ancient.navigationController?.viewControllers.removeAll(ancient)
                })
                completionHandler?(nil)
            }
        }
        
        // MARK: - init
        init(with info: Entity.GroupInfo, logSource: ParentPageSource? = nil) {
            self.groupInfo = info
            self.logSource = logSource
            super.init(nibName: nil, bundle: nil)
        }
                
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - view
        override func viewDidLoad() {
            super.viewDidLoad()

            addListenerViewController()
            view.clipsToBounds = true
//            Logger.PageShow.logger("lv_rm_imp", fromSource, roomInfo.room_id, nil)
        }
        
        func requestLeaveRoom() {
            roomViewController?.requestLeaveRoom()
        }
        
        func addListenerViewController() {
            guard let groupInfo = groupInfo else {
                navigationController?.popViewController(animated: true)
                return
            }
            if roomViewController != nil {
//                listenerViewController?.v.quitRoom()
                roomViewController?.willMove(toParent: nil)
                roomViewController?.beginAppearanceTransition(false, animated: true)
                roomViewController?.view.removeFromSuperview()
                roomViewController?.removeFromParent()
                roomViewController?.endAppearanceTransition()
                roomViewController = nil
            }
            //听众和主播
            let viewModel: AmongChat.GroupRoom.BaseViewModel
            if groupInfo.group.loginUserIsAdmin {
                viewModel = AmongChat.GroupRoom.BroadcasterViewModel(groupInfo: groupInfo, source: logSource)
            } else {
                viewModel = AmongChat.GroupRoom.AudienceViewModel(groupInfo: groupInfo, source: logSource)
            }
            roomViewController = AmongChat.GroupRoom.ViewController(viewModel: viewModel)
            roomViewController?.showInnerJoinLoading = removeLoadingHandler == nil
//            listenerViewController?.fromSource = fromSource
            roomViewController?.willMove(toParent: self)
            roomViewController?.beginAppearanceTransition(true, animated: true)
//            listenerViewController?.broadcasterPictureURL = broadcasterPictureURL
//            listenerViewController?.broadcasterName = broadcasterName
            if self.previousRoomInfo != nil {
//                roomViewController?.enterRoomErrorHandler = { [weak self] in
//                    self?.broadcasterPictureURL = nil
//                    self?.broadcasterName = nil
//                    //clear
//                    self?.roomInfo = self?.previousRoomInfo
//                    self?.previousRoomInfo = nil
//                    //back to previous
//                    self?.addListenerViewController()
//                }
            }
            addChild(roomViewController!)
            roomViewController?.view.frame = self.view.frame
            view.addSubview(roomViewController!.view)
            roomViewController?.didMove(toParent: self)
            roomViewController?.endAppearanceTransition()
//            roomViewController?.showInnerJoinLoading = true
//            roomViewController?.switchLiveRoomHandler = { [weak self] nextRoom in
//                self?.logSource = .roomSource
//                self?.previousRoomInfo = room
//                self?.room = nextRoom
//                self?.addListenerViewController()
//            }
            roomViewController?.showContainerLoading = { [weak self] isShow in
                self?.removeLoadingHandler?()
                self?.view.isUserInteractionEnabled = true
                if isShow {
                    self?.removeLoadingHandler = self?.view.raft.show(.loading)
                    self?.view.isUserInteractionEnabled = false
                }
            }
            if let hud = self.view.raft.topHud() {
                self.view.bringSubviewToFront(hud)
            }
        }
        
//        func switchToLive(_ room: Entity.Room) {
////            broadcasterPictureURL = nil
////            broadcasterName = nil
//            //save previous
////            previousRoomInfo = roomViewController?.
////            roomInfo = Entity.Room(["room_id": roomId, "broadcaster": ["uid": Int(roomId)]])!
//            addListenerViewController()
//        }
    }
}
