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
        
        private var dataSource: [Int: Entity.RoomUser] = [:] {
            didSet {
                guard UIApplication.appDelegate?.isApplicationActiveReplay.value == true else {
                    return
                }
                updateSeats()
            }
        }
        
        fileprivate var viewCache: [Int: AmongChat.Room.UserCell] = [:]
        
        let viewModel: AmongChat.Room.ViewModel
                
        var room: Entity.Room! {
            didSet {
                dataSource = room.userListMap
            }
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
        
        var userProfileSheetActionHandler: ((AmongSheetController.ItemType, _ user: Entity.RoomUser) -> Void)?
        
        init(room: Entity.Room, itemStyle: ItemStyle = .normal, viewModel: AmongChat.Room.ViewModel) {
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
        
        func fetchRealation(with user: Entity.RoomUser) {
            guard user.uid != Settings.loginUserId else {
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
            let isBlocked = relation.isBlocked ?? false
            let blockItem: AmongSheetController.ItemType = isBlocked ? .unblock : .block
            
            let muteItem: AmongSheetController.ItemType = viewModel.mutedUser.contains(user.uid.uInt) ? .unmute : .mute
            if viewModel.roomReplay.value.roomUserList.first?.uid == Settings.loginUserId {
                items.append(.kick)
            }
            
            items.append(contentsOf: [blockItem, muteItem, .report, .cancel])

            AmongSheetController.show(with: user, items: items, in: viewController) { [weak self] item in
                Logger.Action.log(.room_user_profile_clk, categoryValue: self?.room.topicId, item.rawValue)
                self?.userProfileSheetActionHandler?(item, user)
            }
        }
        
        func select(_ user: Entity.RoomUser?) {
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
                guard let user = user else {
                    selectUserHandler?(nil)
                    return
                }
                fetchRealation(with: user)
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
            guard let cell = nilableCell else {
                return
            }
            // callin状态
            cell.clickAvatarHandler = { [weak self] user in
                self?.select(user)
            }
            if style == .kick, let item = dataSource[index] {
                cell.isKickSelected = selectedKickUser.contains(item.uid)
            } else {
                cell.isKickSelected = false
            }
            cell.bind(dataSource[index], topic: room.topicType, index: index + 1)
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
