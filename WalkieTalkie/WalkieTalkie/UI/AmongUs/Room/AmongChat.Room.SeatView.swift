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

extension AmongChat.Room {
    class SeatView: UIView {
        private let fixedListLength = Int(10)

        fileprivate lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
    //            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - itemSpacing * 4) / 5
            let cellWidth: CGFloat = 60
            var hInset: CGFloat = (UIScreen.main.bounds.width - cellWidth * 5) / 2
            let itemSpacing: CGFloat
            if hInset > 40 {
                itemSpacing = (hInset - 40) * 2 / 4
                hInset = 40
            } else {
                itemSpacing = 0
            }
            layout.itemSize = CGSize(width: cellWidth, height: 125.5)
            layout.minimumInteritemSpacing = itemSpacing
            layout.minimumLineSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 0, left: hInset, bottom: 0, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
        
        init(room: Entity.Room) {
            self.room = room
            super.init(frame: .zero)
            bindSubviewEvent()
            configureSubview()
        }
        
//        override init(frame: CGRect) {
//            super.init(frame: frame)
//            bindSubviewEvent()
//            configureSubview()
//        }
        
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
//                maker.left.right.equalToSuperview()
//                maker.top.equalTo(configView.snp.bottom).offset(40)
//                maker.height.equalTo(251)
            }
        }
        
        func showAvatarLongPressSheet(with user: Entity.RoomUser) {
//            AmongSheetController.show(with: <#T##Entity.RoomUser?#>, items: <#T##[AmongSheetController.ItemType]#>, in: <#T##ViewController#>, actionHandler: <#T##((AmongSheetController.ItemType) -> Void)?##((AmongSheetController.ItemType) -> Void)?##(AmongSheetController.ItemType) -> Void#>)
            guard let viewController = viewContainingController() else {
                return
            }
            AmongSheetController.show(with: user, items: [.block, .mute, .report, .cancel], in: viewController) { item in
                
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(AmongChat.Room.UserCell.self), for: indexPath)
        if let cell = cell as? AmongChat.Room.UserCell {
            if style == .kick, let user = dataSource[indexPath.item] {
                cell.isKickSelected = selectedKickUser.contains(user.uid)
            } else {
                cell.isKickSelected = false
            }
            cell.avatarLongPressHandler = { [weak self] user in
//                self?.showAvatarLongPressSheet(with: user)
            }
            cell.bind(dataSource[indexPath.item], topic: room.topicId, index: indexPath.item + 1)
        }
        return cell
    }
    
}

extension AmongChat.Room.SeatView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if style == .kick {
            if let user = dataSource[indexPath.item],
               user.uid != Settings.loginUserId {
                if selectedKickUser.contains(user.uid) {
                    selectedKickUser.remove(user.uid)
                } else {
                    selectedKickUser.insert(user.uid)
                }
            }
        } else {
            selectUserHandler?(dataSource[indexPath.item])
        }
    }
    
}

extension Reactive where Base: AmongChat.Room.SeatView {
//    var multiHostItems: Binder<[Seats.Item]> {
//        return Binder(base) { view, items in
//            cdPrint("[HostSeat] - will trigger reload: \(items.map { $0.userInfo.suid })")
//            guard items.count == Room.HostSeat.countOfSeat || items.count == Room.Dating.countOfSeat else {
//                return
//            }
//            cdPrint("[HostSeat] - did trigger reload: \(items.map { $0.userInfo.suid })")
//            view.multiHostItems = items
//        }
//    }
    
    var soundAnimation: Binder<Int?> {
        return Binder(base) { view, index in
            guard let index = index, let cell = view.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? AmongChat.Room.UserCell else { return }
//            guard let index = index, let cell = view.cacheCell[index] else { return }
            cell.startSoundAnimation()
        }
    }
}
