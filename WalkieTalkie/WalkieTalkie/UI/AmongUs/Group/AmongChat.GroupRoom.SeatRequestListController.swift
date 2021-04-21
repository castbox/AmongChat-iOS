//
//  AmongChat.GroupRoom.SeatRequestListController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import HWPanModal

extension AmongChat.GroupRoom {
    
//    class SeatRequestViewModel {
//        //        static let shared: JoinRequestViewModel?
//        let gid: String
//
//        var dataSourceReplay = BehaviorRelay<[Entity.CallInUser]>(value: [])
//
//        let bag = DisposeBag()
//
//        init(with gid: String) {
//            self.gid = gid
//
//            IMManager.shared.newPeerMessageObservable
//                .filter { $0.msgType == .groupApply }
//                .subscribe(onNext: { [weak self] message in
//                    guard let applyMsg = message as? Peer.GroupApplyMessage,
//                          applyMsg.action == .request else {
//                        return
//                    }
//                    //                    self?.updateCount()
//                })
//                .disposed(by: bag)
//        }
//    }
    
    class SeatRequestListController: WalkieTalkie.ViewController {
        
        enum Action {
            case accept
            case reject
        }
        
        private lazy var titleView: AmongChat.GroupRoom.MembersController.HeaderView = {
            let v = AmongChat.GroupRoom.MembersController.HeaderView()
            //            v.title = R.string.localizable.groupRoomMembersTitle()
            return v
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(nibWithCellClass: AmongGroupJoinRequestCell.self)
            //            tb.register(cellWithClass: MembersCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var userList: [Entity.CallInUser] = [] {
            didSet {
                if userList.isEmpty {
                    addNoDataView(R.string.localizable.groupRoomApplySeatListEmpty(), image: R.image.ac_among_apply_empty())
                } else {
                    removeNoDataView()
                }
                tableView.reloadData()
            }
        }
        var actionHandler: ((Entity.CallInUser, Action) -> Void)?
        
        private let group: Entity.Group
        private let dataSourceReplay: BehaviorRelay<[Entity.CallInUser]>
        
        init(with group: Entity.Group, replay: BehaviorRelay<[Entity.CallInUser]>) {
            self.group = group
            self.dataSourceReplay = replay
            super.init(nibName: nil, bundle: nil)
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            //
            dataSourceReplay
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] source in
                    self?.titleView.title = R.string.localizable.groupRoomRaisedHandsTitle(source.count.string)
                    self?.userList = source
                })
                .disposed(by: bag)
        }
        
        override func addNoDataView(_ message: String, image: UIImage? = nil) {
            removeNoDataView()
            let v = NoDataView(with: message, image: image, topEdge: 60)
            view.addSubview(v)
            v.snp.makeConstraints { (maker) in
                maker.top.equalTo(60)
                maker.left.right.equalToSuperview()
                maker.height.equalTo(500 - 120)
            }
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = "222222".color()
            
            view.addSubviews(views: titleView)
            
            titleView.snp.makeConstraints { (maker) in
                maker.top.leading.trailing.equalToSuperview()
                maker.height.equalTo(65.5)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(titleView.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
        }
    }
}
// MARK: - UITableView
extension AmongChat.GroupRoom.SeatRequestListController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: AmongGroupJoinRequestCell.self)
        if let user = userList.safe(indexPath.row) {
            cell.style = .applyOnSeat
            cell.bind(user.user, showFollowsCount: true)
            cell.actionHandler = { [weak self] action in
                switch action {
                case .accept:
                    Logger.Action.log(.group_raise_hands_accept, categoryValue: self?.group.topicId)
                    self?.actionHandler?(user, .accept)
                case .reject:
                    Logger.Action.log(.group_raise_hands_reject, categoryValue: self?.group.topicId)
                    self?.actionHandler?(user, .reject)
                case .ignore:
                    ()
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 124
    }
}

extension AmongChat.GroupRoom.SeatRequestListController {
    
    override func longFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .topInset, height: 0)
    }
    
    override func shortFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: Frame.Scale.height(500))
    }
    
    override func panScrollable() -> UIScrollView? {
        return tableView
    }
    
    override func allowsExtendedPanScrolling() -> Bool {
        return true
    }
    
    override func cornerRadius() -> CGFloat {
        return 20
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
}



