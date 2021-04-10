//
//  AmongChat.GroupRoom.JoinRequestListController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import HWPanModal

extension AmongChat.GroupRoom {
    class JoinRequestViewModel {
//        static let shared: JoinRequestViewModel?
        let gid: String
        
        var countReplay = BehaviorRelay(value: 0)
        
        let bag = DisposeBag()
        
        init(with gid: String) {
            self.gid = gid
            
            IMManager.shared.newPeerMessageObservable
                .filter { $0.msgType == .groupApply }
                .subscribe(onNext: { [weak self] message in
                    guard let applyMsg = message as? Peer.GroupApplyMessage,
                          applyMsg.action == .request else {
                        return
                    }
                    self?.updateCount()
                })
                .disposed(by: bag)
            
            self.updateCount()
        }
        
        func updateCount() {
            //reqest
            loadData()
                .subscribe()
                .disposed(by: bag)
        }
        
        func loadData() -> Single<Entity.GroupUserList> {
            return Request.appliedUsersOfGroup(gid, skipMs: 0)
                .do(onSuccess: { [weak self](data) in
                    self?.countReplay.accept(data.count ?? 0)
                })
        }
        
        func loadMore(skipMs: Double) -> Single<Entity.GroupUserList> {
            Request.appliedUsersOfGroup(gid, skipMs: skipMs)
                .do(onSuccess: { [weak self](data) in
                    self?.countReplay.accept(data.count ?? 0)
                })
        }
    }
    
    
    class JoinRequestListController: WalkieTalkie.ViewController {
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
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        let viewModel: AmongChat.GroupRoom.JoinRequestViewModel
        var gid: String { viewModel.gid }
        
        init(with viewModel: AmongChat.GroupRoom.JoinRequestViewModel) {
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = "222222".color()
            
            view.addSubviews(views: titleView)
            
            titleView.snp.makeConstraints { (maker) in
                maker.top.leading.trailing.equalToSuperview()
                maker.height.equalTo(65.5)
                //                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(titleView.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            tableView.pullToRefresh { [weak self] in
                self?.loadData()
            }
            tableView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            
            viewModel.loadData()
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.userList = data.list
                    if self.userList.isEmpty {
                        self.addNoDataView(R.string.localizable.groupRoomApplyGroupListEmpty(), image: R.image.ac_among_apply_empty())
                    }
                    self.titleView.title = R.string.localizable.groupRoomJoinRequestTitle(data.count?.string ?? "")
                    self.tableView.endLoadMore(data.more)
                }, onError: { [weak self](error) in
                    removeBlock()
                    self?.addErrorView({ [weak self] in
                        self?.loadData()
                    })
                    cdPrint("followingList error: \(error.localizedDescription)")
                }).disposed(by: bag)
        }
        
        private func loadMore() {
            let skipMS = userList.last?.opTime ?? 0
            viewModel.loadMore(skipMs: skipMS)
                .subscribe(onSuccess: { [weak self](data) in
                    //                    guard let data = data else { return }
                    let list =  data.list
                    var origenList = self?.userList
                    list.forEach({ origenList?.append($0)})
                    self?.userList = origenList ?? []
                    self?.tableView.endLoadMore(data.more)
                }, onError: { (error) in
                    cdPrint("followingList error: \(error.localizedDescription)")
                }).disposed(by: bag)
        }
        
        private func handlerJoinRequest(for uid: Int, accept: Bool, at index: IndexPath) {
            let removeBlock = view.raft.show(.loading)
            Request.handleGroupApply(of: uid, groupId: gid, accept: accept)
                .subscribe(onSuccess: { [weak self] result in
                    removeBlock()
                    //remove
                    let list = self?.userList.filter { $0.uid != uid } ?? []
                    self?.userList = list
//                    self?.tableView.beginUpdates()
//                    self?.tableView.deleteRows(at: [index], with: .automatic)
//                    self?.tableView.endUpdates()
                }, onError: { (error) in
                    removeBlock()
                }).disposed(by: bag)
        }
    }
}
// MARK: - UITableView
extension AmongChat.GroupRoom.JoinRequestListController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: AmongGroupJoinRequestCell.self)
        if let user = userList.safe(indexPath.row) {
            cell.profile = user
            cell.actionHandler = { [weak self] action in
                switch action {
                case .accept:
                    self?.handlerJoinRequest(for: user.uid, accept: true, at: indexPath)
                case .reject:
                    ()
                case .ignore:
                    self?.handlerJoinRequest(for: user.uid, accept: false, at: indexPath)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 124
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

    }
}

extension AmongChat.GroupRoom.JoinRequestListController {
    
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


