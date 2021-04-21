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
                if userList.isEmpty {
                    addNoDataView(R.string.localizable.groupRoomApplyGroupListEmpty(), image: R.image.ac_among_apply_empty())
                } else {
                    removeNoDataView()
                }
                titleView.title = R.string.localizable.groupRoomJoinRequestTitle(userList.count.string)
            }
        }
        let viewModel: AmongChat.GroupRoom.JoinRequestViewModel
        var gid: String { viewModel.gid }
        let topicId: String
        init(with topicId: String, viewModel: AmongChat.GroupRoom.JoinRequestViewModel) {
            self.topicId = topicId
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
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            viewModel.loadData()
                .subscribe(onSuccess: { [weak self] data in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.userList = data.list
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
                    self?.viewModel.updateCount()
                    //
                    if list.isEmpty {
                        //dismiss
                        self?.dismiss(animated: true, completion: nil)
                    }
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
            cell.bind(user, showFollowsCount: true)
            cell.actionHandler = { [weak self] action in
                switch action {
                case .accept:
                    Logger.Action.log(.group_broadcaster_join_request_accept, categoryValue: self?.topicId)
                    self?.handlerJoinRequest(for: user.uid, accept: true, at: indexPath)
                case .reject:
                    ()
                case .ignore:
                    Logger.Action.log(.group_broadcaster_join_request_ignore, categoryValue: self?.topicId)
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


