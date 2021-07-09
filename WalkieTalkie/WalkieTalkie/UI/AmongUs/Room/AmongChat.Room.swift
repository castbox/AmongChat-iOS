//
//  AmongChat.Room.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol LiveDescribableViewController: UIViewController {
    var liveId: String { get }
    func quitLive() -> Void
}

extension AmongChat {
    struct Room {}
}

extension AmongChat.Room {
    class ContainerController: WalkieTalkie.ViewController, GestureBackable {
        var isEnableScreenEdgeGesture: Bool = false
        
        var room: Entity.RoomInfo!
        var roomViewController: AmongChat.Room.ViewController?
        var broadcasterPictureURL: String?
        var broadcasterName: String?
        var enterRoomErrorHandler: (() -> Void)?
        var previousRoomInfo: Entity.RoomInfo?
        
        var logSource: ParentPageSource?
        var removeLoadingHandler: CallBack? = nil
        
        static func join(room: Entity.RoomInfo, from controller: UIViewController, logSource: ParentPageSource? = nil, completionHandler: ((Error?) -> Void)? = nil) {
            controller.checkMicroPermission { [weak controller] in
                guard let controller = controller else {
                    return
                }
                Logger.Action.log(.room_enter, categoryValue: room.room.topicId, logSource?.key)
                //show loading
//                let viewModel = ViewModel.make(room, logSource)
//                self.show(from: controller, with: viewModel)
                let vc = AmongChat.Room.ContainerController(with: room, logSource: logSource)
                controller.navigationController?.pushViewController(vc, completion: { [weak controller] in
                    guard let ancient = controller,
                          (ancient is AmongChat.CreateRoom.ViewController || ancient is AmongChat.GroupRoom.ContainerController || ancient is AmongChat.Room.ContainerController) else { return }
                    ancient.navigationController?.viewControllers.removeAll(ancient)
                })
                completionHandler?(nil)
                UIApplication.appDelegate?.liveRoom = vc
            }
        }
        
        // MARK: - init
        init(with room: Entity.RoomInfo, logSource: ParentPageSource? = nil) {
            self.room = room
            self.logSource = logSource
//            self.broadcasterPictureURL = roomInfo.broadcaster?.picture_url
//            self.broadcasterName = roomInfo.broadcaster?.name
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
            guard let room = room else {
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
            let viewModel = ViewModel(roomInfo: room, source: logSource)
            roomViewController = AmongChat.Room.ViewController(viewModel: viewModel)
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
            roomViewController?.switchLiveRoomHandler = { [weak self] nextRoom in
                self?.logSource = .roomSource
                self?.previousRoomInfo = room
                self?.room = nextRoom
                self?.addListenerViewController()
            }
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

extension AmongChat.Room.ContainerController: LiveDescribableViewController {
    
    var liveId: String {
        return room.room.roomId
    }
    
    func quitLive() {
        roomViewController?.requestLeaveRoom(completionHandler: { [weak self] in
            self?.navigationController?.viewControllers.removeAll(where: { $0 == self })
        })
    }
    
}
