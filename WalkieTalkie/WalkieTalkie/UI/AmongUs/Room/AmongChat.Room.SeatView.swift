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

extension AmongChat.Room {
    
    class SeatFlowLayout: UICollectionViewFlowLayout {
//        var margin: CGFloat = 15
//        var padding: CGFloat = 4
//        let itemWidth: CGFloat = 60
//        let itemHeight: CGFloat = 125.5
//        var activityItemWidth: CGFloat = (Frame.Screen.width - 30 - 4) / 2
        var itemAttributesArray = [UICollectionViewLayoutAttributes]()
        
        override func prepare() {
            super.prepare()
            
            let cellWidth: CGFloat = 60
            var hInset: CGFloat = (UIScreen.main.bounds.width - cellWidth * 5) / 2
            let itemSpacing: CGFloat
            if hInset > 20 {
                itemSpacing = (hInset - 20) * 2 / 4
                hInset = 20
            } else {
                itemSpacing = 0
                hInset = hInset.floor
            }
            itemSize = CGSize(width: cellWidth, height: 125.5)
            minimumInteritemSpacing = itemSpacing
            minimumLineSpacing = 0
            sectionInset = UIEdgeInsets(top: 0, left: hInset, bottom: 0, right: hInset)

//            itemSize = CGSize(width: itemWidth, height: itemHeight)
//            minimumLineSpacing = 4
//            minimumInteritemSpacing = 0
            scrollDirection = .horizontal
            
            // 刷新清空
            itemAttributesArray.removeAll()
            
            
//            let sectionCount = collectionView?.numberOfSections ?? 0
//            for section in 0..<sectionCount {
            let itemCount = collectionView?.numberOfItems(inSection: 0) ?? 0
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: 0)
                let attribute = layoutAttributesForItem(at: indexPath)
                if let attr = attribute {
                    itemAttributesArray.append(attr)
                }
            }
        }

        override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
            return itemAttributesArray
        }
        
        override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
            let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
//            let page: CGFloat = CGFloat(indexPath.item / 8)
            let row: CGFloat = CGFloat(indexPath.item % 5)
            let col: CGFloat = CGFloat(indexPath.item / 5)
            let x = sectionInset.left + row * (itemSize.width + minimumInteritemSpacing)
            let y = sectionInset.top + col * itemSize.height
            cdPrint("x: \(x) \ny: \(y)")
            attribute.frame = CGRect(x: x, y: y, width: itemSize.width, height: itemSize.height)
            return attribute
        }
        
        override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
            return true
        }
    }
}

extension AmongChat.Room {
    class SeatView: UIView {
        private let fixedListLength = Int(10)

        fileprivate lazy var collectionView: UICollectionView = {
            let v = UICollectionView(frame: .zero, collectionViewLayout: SeatFlowLayout())
            v.register(UserCell.self, forCellWithReuseIdentifier: NSStringFromClass(UserCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.isScrollEnabled = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = nil
            return v
        }()
        
        private var dataSource: [Int: Entity.RoomUser] = [:] {
            didSet {
                collectionView.reloadData()
            }
        }
        
        private var viewCache: [Int: AmongChat.Room.UserCell] = [:]
        
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
                collectionView.reloadData()
            }
        }
        
        var selectedKickUserHandler: (([Int]) -> Void)?
        
        var selectUserHandler: ((Entity.RoomUser?) -> Void)?
        
        var userProfileSheetActionHandler: ((AmongSheetController.ItemType, _ user: Entity.RoomUser) -> Void)?
        
        init(room: Entity.Room, viewModel: AmongChat.Room.ViewModel) {
            self.room = room
            self.viewModel = viewModel
            super.init(frame: .zero)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            
        }
        
        private func configureSubview() {
            backgroundColor = .clear
            
            addSubview(collectionView)
            
            collectionView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
        func showAvatarSheet(with user: Entity.RoomUser) {
            guard user.uid != Settings.loginUserId,
                  let viewController = containingController else {
                return
            }
            Logger.Action.log(.room_user_profile_imp, categoryValue: room.topicId)

            let muteItem: AmongSheetController.ItemType = viewModel.mutedUser.contains(user.uid.uInt) ? .unmute : .mute
            let blockItem: AmongSheetController.ItemType = viewModel.blockedUsers.contains(where: { $0.uid == user.uid}) ? .unblock : .block
            var items: [AmongSheetController.ItemType] = [.userInfo, .profile]
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
    //                self.onShareBtn()
                    selectUserHandler?(nil)
                    return
                }
                showAvatarSheet(with: user)
            }
        }
    }
}

extension AmongChat.Room.SeatView: UICollectionViewDataSource {
    
    // MARK: - UICollectionView
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fixedListLength
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = viewCache[indexPath.item]
        if cell == nil {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(AmongChat.Room.UserCell.self), for: indexPath) as? AmongChat.Room.UserCell
            viewCache[indexPath.item] = cell
            cell?.emojis = room.topicType.roomEmojis
            cell?.clickAvatarHandler = { [weak self] user in
                self?.select(user)
            }
        }
        if let cell = cell {
            if style == .kick, let user = dataSource[indexPath.item] {
                cell.isKickSelected = selectedKickUser.contains(user.uid)
            } else {
                cell.isKickSelected = false
            }
//            cell.avatarLongPressHandler = { [weak self] user in
//            }
            cell.bind(dataSource[indexPath.item], topic: room.topicType, index: indexPath.item + 1)
        }
        return cell!
    }
    
}

extension AmongChat.Room.SeatView: UICollectionViewDelegate {
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//    }
    
}

extension Reactive where Base: AmongChat.Room.SeatView {
    var soundAnimation: Binder<Int?> {
        return Binder(base) { view, index in
            guard let index = index, let cell = view.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? AmongChat.Room.UserCell else { return }
//            guard let index = index, let cell = view.cacheCell[index] else { return }
            cell.startSoundAnimation()
        }
    }
}
