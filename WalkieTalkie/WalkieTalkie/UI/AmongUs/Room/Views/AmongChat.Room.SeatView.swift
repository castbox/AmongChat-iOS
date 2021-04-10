//
//  AmongChatSeatView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 18/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVGAPlayer
import SwiftyUserDefaults

extension AmongChat.Room {
    class SeatItem {
        let isEmpty: Bool
        var callContent: Peer.CallMessage
        var user: Entity.RoomUser?
        
        var isLock: Bool = false
        var isActive: Bool = false
        var isMuted: Bool = false
        
//        var emoji: EmojiContent?
//        var emojiPlayEndHandler: (EmojiContent?) -> Void = { _ in }
        
        var isValid: Bool {
            return !callContent.gid.isEmpty && user?.uid != nil
        }
        
        init(_ gid: String, _ user: Entity.RoomUser? = nil, action: Peer.CallMessage.Action = .none, callContent: Peer.CallMessage? = nil) {
            
            self.callContent = callContent ?? Peer.CallMessage.empty(gid: gid)
            self.user = user
            self.isEmpty = user == nil
//            self.emoji = nil
        }
        
        func clear() {
            user = nil
            callContent = Peer.CallMessage.empty(gid: callContent.gid)
            isActive = false
            isLock = false
            isMuted = false
        }
        
        func toCallInUser() -> Entity.CallInUser {
            return Entity.CallInUser(message: callContent, startTimeStamp: 0)
        }
        
        static func ==(_ lhs: SeatItem, _ rhs: SeatItem) -> Bool {
            return lhs.user?.uid == rhs.user?.uid && lhs.callContent.action == rhs.callContent.action
        }
    }
}

extension AmongChat.Room {
    class SeatView: UIView {
        
        enum ItemStyle {
            case normal
            case group
        }
        
        let bag = DisposeBag()
        
        private let fixedListLength = Int(10)
        static let itemWidth: CGFloat = ((UIScreen.main.bounds.width - 20 * 2) / 5).floor
        static var itemHeight: CGFloat = 125.5
        lazy var leftEdge: CGFloat = (UIScreen.main.bounds.width - AmongChat.Room.SeatView.itemWidth * 5) / 2

        lazy var topStackView: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [])
            stack.axis = .horizontal
            stack.spacing = 0
            stack.alignment = .fill
            stack.distribution = .fillEqually
            return stack
        }()
        
        lazy var bottomStackView: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [])
            stack.axis = .horizontal
            stack.spacing = 0
            stack.alignment = .fill
            stack.distribution = .fillEqually
            return stack
        }()
        
        var dataSource: [AmongChat.Room.SeatItem] = [] {
            didSet {
                guard UIApplication.appDelegate?.isApplicationActiveReplay.value == true else {
                    return
                }
                //组装
                updateSeats()
            }
        }
        
        fileprivate var viewCache: [Int: AmongChat.Room.UserCell] = [:]
        
        let viewModel: AmongChat.BaseRoomViewModel
                
        var room: RoomInfoable! {
            didSet {
//                dataSource = room.userListMap
            }
        }
        
        var group: Entity.GroupRoom? {
            return room as? Entity.GroupRoom
        }
        
        var style: AmongChat.Room.Style = .normal {
            didSet {
                selectedKickUser.removeAll()
            }
        }
        
        private var selectedKickUser = Set<Int>() {
            didSet {
                selectedKickUserHandler?(Array(selectedKickUser))
                updateSeats()
            }
        }
        
        var itemStyle: ItemStyle = .normal {
            didSet {
                AmongChat.Room.SeatView.itemHeight = itemStyle == .normal ? 125.5 : 100
            }
        }
        
        var selectedKickUserHandler: (([Int]) -> Void)?
        
        var selectUserHandler: ((Entity.RoomUser?) -> Void)?
        
        var requestOnSeatHandler: ((Int) -> Void)?
        
        var userProfileSheetActionHandler: ((AmongSheetController.ItemType, _ user: Entity.RoomUser) -> Void)?
        
        init(room: RoomInfoable, itemStyle: ItemStyle = .normal, viewModel: AmongChat.BaseRoomViewModel) {
            self.room = room
            self.viewModel = viewModel
            self.itemStyle = itemStyle
            super.init(frame: .zero)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func play(_ emoji: ChatRoom.EmojiMessage, completionHandler: CallBack?) {
            let cell = viewCache.values.first(where: { cell -> Bool in
                return cell.user?.uid == emoji.user.uid
            })
            cell?.play(emoji) { content in
                completionHandler?()
            }
        }
        
        private func bindSubviewEvent() {

        }
        
        private func configureSubview() {
            backgroundColor = .clear
            
            addSubviews(views: topStackView, bottomStackView)
            
            topStackView.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.leading.trailing.equalToSuperview().inset(leftEdge)
            }
            
            bottomStackView.snp.makeConstraints { (maker) in
                maker.top.equalTo(topStackView.snp.bottom)
                maker.bottom.equalToSuperview()
                maker.leading.trailing.equalToSuperview().inset(leftEdge)
                maker.height.equalTo(topStackView)
            }
            
            updateSeats()
        }
        
        func showDropSelfAlert(with user: Entity.RoomUser) {
            containingController?.showAmongAlert(title: nil, message: R.string.localizable.groupRoomDropSelfTips(), cancelTitle: R.string.localizable.groupRoomNo(), confirmTitle: R.string.localizable.groupRoomYes(), cancelAction: nil, confirmAction: { [weak self] in
                //
                self?.userProfileSheetActionHandler?(.drop, user)
            })
        }
        
        func fetchRealation(with user: Entity.RoomUser) {
            guard user.uid != Settings.loginUserId else {
                if itemStyle == .group {
                    //show alert
                    showDropSelfAlert(with: user)
                }
                return
            }
            let removeBlock = parentViewController?.view.raft.show(.loading)
            Request.relationData(uid: user.uid).asObservable()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] relation in
                    removeBlock?()
                    guard let `self` = self,
                          let data = relation else { return }
                    self.showAvatarSheet(with: user, relation: data)
                }, onError: { error in
                    removeBlock?()
                    cdPrint("relationData error :\(error.localizedDescription)")
                })
                .disposed(by: bag)
        }
        
        func showAvatarSheet(with user: Entity.RoomUser, relation: Entity.RelationData) {
            guard let viewController = containingController else {
                return
            }
            Logger.Action.log(.room_user_profile_imp, categoryValue: room.topicId)
            
            var items: [AmongSheetController.ItemType] = [.userInfo, .profile]

            let isFollowed = relation.isFollowed ?? false
            if !isFollowed {
                items.append(.follow)
            }
            //
            if group?.loginUserIsAdmin == true {
                items.append(.drop)
            }
            let isBlocked = relation.isBlocked ?? false
            let blockItem: AmongSheetController.ItemType = isBlocked ? .unblock : .block
            
            let muteItem: AmongSheetController.ItemType = viewModel.mutedUser.contains(user.uid.uInt) ? .unmute : .mute
            if viewModel.roomReplay.value.userList.first?.uid == Settings.loginUserId {
                items.append(.kick)
            }
            
            items.append(contentsOf: [blockItem, muteItem, .report, .cancel])

            AmongSheetController.show(with: user, items: items, in: viewController) { [weak self] item in
                Logger.Action.log(.room_user_profile_clk, categoryValue: self?.room.topicId, item.rawValue)
                self?.userProfileSheetActionHandler?(item, user)
            }
        }
        
        func select(_ index: Int, user: Entity.RoomUser?) {
            if style == .kick {
                if let user = user,
                   user.uid != Settings.loginUserId {
                    if selectedKickUser.contains(user.uid) {
                        selectedKickUser.remove(user.uid)
                    } else {
                        selectedKickUser.insert(user.uid)
                    }
                }
            } else {
                if let user = user {
                    //区分 style
                    fetchRealation(with: user)
                } else {
                    //
                    if itemStyle == .group {
                        requestOnSeatHandler?(index)
                    } else {
                        selectUserHandler?(nil)
                    }
                }
            }
        }
    }
}

extension AmongChat.Room.SeatView {
    func updateSeats() {
        for index in 0 ..< fixedListLength {
            var nilableCell = viewCache[index]
            if nilableCell == nil {
                //CGRect(x: 0, y: 0, width: AmongChat.Room.SeatView.itemWidth, height: AmongChat.Room.SeatView.itemHeight
                let cell = AmongChat.Room.UserCell(itemStyle: itemStyle)
                if index < 5 {
                    topStackView.addArrangedSubview(cell)
                } else {
                    bottomStackView.addArrangedSubview(cell)
                }
                cell.emojisNames = room.topicType.roomEmojiNames
                viewCache[index] = cell
                nilableCell = cell
            }
            guard let cell = nilableCell, let item = dataSource.safe(index) else {
                return
            }
            // callin状态
            if item.callContent.action == .request {
//                cell.seatButton.setImage(nil, for: .normal)
//                cell.hostNameLabel.text = nil
//                cell.userInfo = nil
//                cell.startLoading()
//                cell.set(item: nil)
                //clear
                cell.clearStyle()
                cell.startLoading()
                continue
            } else {
                cell.stopLoading()
            }
            cell.clickAvatarHandler = { [weak self] user in
                self?.select(index, user: user)
            }
            if style == .kick, let user = item.user {
                cell.isKickSelected = selectedKickUser.contains(user.uid)
            } else {
                cell.isKickSelected = false
            }
            cell.bind(dataSource.safe(index)?.user, topic: room.topicType, index: index + 1)
        }
    }
}

extension Reactive where Base: AmongChat.Room.SeatView {
    var soundAnimation: Binder<Int?> {
        return Binder(base) { view, index in
            guard let index = index,
                  let cell = view.viewCache[index],
                  UIApplication.appDelegate?.isApplicationActiveReplay.value == true else { return }
            
            cell.startSoundAnimation()
        }
    }
}
