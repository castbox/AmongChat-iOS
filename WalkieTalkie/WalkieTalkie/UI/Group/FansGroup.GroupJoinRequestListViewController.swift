//
//  FansGroup.GroupJoinRequestListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/9.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import JXPagingView
import SDCAlertView

extension FansGroup {
    
    class GroupJoinRequestListViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.groupRoomJoinRequest()
            return n
        }()
        
        private(set) lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.register(nibWithCellClass: AmongGroupJoinRequestCell.self)
            tb.register(nibWithCellClass: AmongGroupJoinRequestCellIPad.self)
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = Frame.isPad ? 76 : 124
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            if #available(iOS 11.0, *) {
                tb.contentInsetAdjustmentBehavior = .never
            } else {
                // Fallback on earlier versions
                automaticallyAdjustsScrollViewInsets = false
            }
            tb.backgroundView = emptyView
            return tb
        }()
        
        private lazy var emptyView: UIView = {
            let v = UIView()
            let e = FansGroup.Views.EmptyDataView()
            e.titleLabel.text = R.string.localizable.groupRoomApplyGroupListEmpty()
            v.addSubview(e)
            e.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.leading.greaterThanOrEqualToSuperview().offset(40)
                maker.top.equalTo(100)
            }
            v.isHidden = true
            return v
        }()
        
        private let usersRelay = BehaviorRelay<[Entity.UserProfile]>(value: [])
        private var totalCount: Int = 0
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupId: String
        private let hasNavigationBar: Bool
        
        var requestsCountObservable: Observable<Int> {
            return usersRelay.map { $0.count }.asObservable()
        }
        
        private var listViewDidScrollCallback: ((UIScrollView) -> ())?
        
        init(with groupId: String, hasNavigationBar: Bool = false) {
            self.groupId = groupId
            self.hasNavigationBar = hasNavigationBar
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            fetchRequests()
        }
        
    }
    
}

extension FansGroup.GroupJoinRequestListViewController: UITableViewDataSource {
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersRelay.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if Frame.isPad {
            let cell = tableView.dequeueReusableCell(withClass: AmongGroupJoinRequestCellIPad.self)
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            if let user = usersRelay.value.safe(indexPath.row) {
                cell.bind(user, showFollowsCount: true)
                cell.actionHandler = { [weak self] action in
                    switch action {
                    case .accept:
                        self?.handleJoinRequest(for: user.uid, accept: true)
                    case .reject:
                        ()
                    case .ignore:
                        self?.handleJoinRequest(for: user.uid, accept: false)
                    }
                }
            }
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withClass: AmongGroupJoinRequestCell.self)
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            if let user = usersRelay.value.safe(indexPath.row) {
                cell.bind(user, showFollowsCount: true, verifyStayle: .black)
                cell.actionHandler = { [weak self] action in
                    switch action {
                    case .accept:
                        self?.handleJoinRequest(for: user.uid, accept: true)
                    case .reject:
                        ()
                    case .ignore:
                        self?.handleJoinRequest(for: user.uid, accept: false)
                    }
                }
            }
            return cell
            
        }
    }
    
}

extension FansGroup.GroupJoinRequestListViewController: UITableViewDelegate {
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let user = usersRelay.value.safe(indexPath.row) {
            let vc = Social.ProfileViewController(with: user.uid)
            vc.followedHandle = { [weak self](followed) in
                guard let `self` = self else { return }
            }
            self.navigationController?.pushViewController(vc)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        
        let l = UILabel()
        l.font = R.font.nunitoExtraBold(size: 18)
        l.textColor = UIColor(hex6: 0xABABAB)
        l.text = R.string.localizable.groupRoomJoinRequestTitle("\(totalCount)")
        
        let handlelAllButton: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setImage(R.image.ac_group_all_join_requests(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    //MARK: - handle all requests
                    self?.popUpHandleAll(btn)
                })
                .disposed(by: bag)
            
            return btn
        }()
        
        v.addSubviews(views: l, handlelAllButton)
        
        l.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
            maker.trailing.equalTo(handlelAllButton.snp.leading).offset(-20)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(25)
        }
        
        handlelAllButton.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(l)
            maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
        }
        
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 37
    }
}

extension FansGroup.GroupJoinRequestListViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: tableView)
        
        if hasNavigationBar {
            
            view.addSubview(navView)
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            tableView.snp.makeConstraints { (maker) in
                maker.top.equalTo(navView.snp.bottom)
                maker.leading.trailing.bottom.equalToSuperview()
            }
            
        } else {
            tableView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
        tableView.pullToLoadMore { [weak self] in
            self?.fetchRequests()
        }
    }
    
    private func setUpEvents() {
        usersRelay
            .skip(1)
            .subscribe(onNext: { [weak self] (requests) in
                self?.emptyView.isHidden = requests.count > 0
                self?.tableView.reloadData()
            })
            .disposed(by: bag)
    }
    
    private func fetchRequests() {
        guard hasMoreData,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        Request.appliedUsersOfGroup(groupId,
                                    skipMs: usersRelay.value.last?.opTime ?? 0)
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
            })
            .subscribe(onSuccess: { [weak self] (groupUserList) in
                
                guard let `self` = self else {
                    return
                }
                self.totalCount = groupUserList.count ?? 0
                var members = self.usersRelay.value
                members.append(contentsOf: groupUserList.list)
                self.usersRelay.accept(members)
                self.hasMoreData = groupUserList.more
                self.tableView.endLoadMore(groupUserList.more)
            })
            .disposed(by: bag)
        
    }
    
    private func handleJoinRequest(for uid: Int, accept: Bool) {
        let removeBlock = view.raft.show(.loading)
        Request.handleGroupApply(of: uid, groupId: groupId, accept: accept)
            .do(onDispose: { () in
                removeBlock()
            })
            .subscribe(onSuccess: { [weak self] result in
                guard let `self` = self else { return }
                //remove
                
                var users = self.usersRelay.value
                users.removeAll { $0.uid == uid }
                self.usersRelay.accept(users)
                
            }, onError: { (error) in
                
            }).disposed(by: bag)
    }
    
    private func popUpHandleAll(_ sender: UIView) {
        
        let btnFrameInWindow = sender.superview!.convert(sender.frame, to: UIApplication.shared.keyWindow)
        let popUp = HandleAllRequestsPopup(calloutButtonFrame: btnFrameInWindow)
        popUp.actionHandler = { [weak self] action in
            self?.handleAllJoinRequest(accept: action == .accept)
        }
        popUp.modalPresentationStyle = .overCurrentContext
        present(popUp, animated: false)
    }
    
    private func handleAllJoinRequest(accept: Bool) {
        
        let removeBlock = view.raft.show(.loading)
        
        Request.handleAllGroupApply(of: groupId, accept: accept)
            .do(onDispose: { () in
                removeBlock()
            })
            .subscribe(onSuccess: { [weak self] _ in
                
                guard let `self` = self else { return }
                
                var users = self.usersRelay.value
                users.removeAll()
                self.usersRelay.accept(users)

            }, onError: { [weak self] error in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatCommonError()))
            })
            .disposed(by: self.bag)
    }
}

extension FansGroup.GroupJoinRequestListViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        listViewDidScrollCallback?(scrollView)
    }
    
}

extension FansGroup.GroupJoinRequestListViewController: JXPagingViewListViewDelegate {
    
    func listView() -> UIView {
        return view
    }
    
    func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> ()) {
        listViewDidScrollCallback = callback
    }
    
    func listScrollView() -> UIScrollView {
        return tableView
    }
    
}

extension FansGroup.GroupJoinRequestListViewController {
    
    class HandleAllRequestsPopup: WalkieTalkie.ViewController {
        
        class ItemView: UIView {
            
            private let bag = DisposeBag()
            
            private(set) lazy var icon: UIImageView = {
                let i = UIImageView()
                return i
            }()
            
            private(set) lazy var titleLabel: UILabel = {
                let l = UILabel()
                l.textColor = .white
                l.font = R.font.nunitoExtraBold(size: 16)
                return l
            }()
            
            private lazy var tap: UITapGestureRecognizer = {
                let gr = UITapGestureRecognizer()
                gr.rx.event.subscribe(onNext: { [weak self] _ in
                    self?.tapHandler?()
                })
                .disposed(by: bag)
                return gr
            }()
            
            var tapHandler: (() -> Void)? = nil
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                setUpLayout()
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            private func setUpLayout() {
                
                addSubviews(views: icon, titleLabel)
                
                icon.snp.makeConstraints { maker in
                    maker.width.height.equalTo(24)
                    maker.centerY.equalToSuperview()
                    maker.leading.equalTo(20)
                }
                
                titleLabel.snp.makeConstraints { maker in
                    maker.centerY.equalToSuperview()
                    maker.leading.equalTo(icon.snp.trailing).offset(8)
                    maker.trailing.equalToSuperview().offset(-20)
                }
                
                addGestureRecognizer(tap)
            }
        }
        
        private lazy var callout: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.layer.cornerRadius = 12
            v.addSubviews(views: acceptView, ignoreView)
            
            acceptView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(40)
                maker.width.equalTo(202)
                maker.top.equalTo(28)
            }
            
            ignoreView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.size.equalTo(acceptView)
                maker.top.equalTo(acceptView.snp.bottom).offset(20)
                maker.bottom.equalToSuperview().offset(-28)
            }
            
            return v
        }()
        
        private lazy var acceptView: ItemView = {
            let v = ItemView()
            v.titleLabel.text = R.string.localizable.amongChatGroupAcceptAll()
            v.icon.image = R.image.ac_group_accept_all()
            v.tapHandler = { [weak self] in
                self?.actionHandler?(.accept)
                self?.dismiss()
            }
            return v
        }()
        
        private lazy var ignoreView: ItemView = {
            let v = ItemView()
            v.titleLabel.text = R.string.localizable.amongChatGroupIgnoreAll()
            v.icon.image = R.image.ac_group_ignore_all()
            v.tapHandler = { [weak self] in
                self?.actionHandler?(.ignore)
                self?.dismiss()
            }
            return v
        }()
        
        private lazy var bgTap: UITapGestureRecognizer = {
            let gr = UITapGestureRecognizer()
            gr.rx.event.subscribe(onNext: { [weak self] _ in
                self?.dismiss()
            })
            .disposed(by: bag)
            return gr
        }()
        
        enum Action {
            case accept, ignore
        }
        
        var actionHandler: ((Action) -> Void)? = nil
        
        private let calloutButtonFrame: CGRect
        
        init(calloutButtonFrame: CGRect) {
            self.calloutButtonFrame = calloutButtonFrame
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
        }
        
        private func setUpLayout() {
            
            view.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.7)
            
            view.addSubviews(views: callout)
            
            callout.snp.makeConstraints { maker in
                maker.trailing.equalToSuperview().offset(-20)
                
                let btnBottomSpace = UIScreen.main.bounds.height - calloutButtonFrame.maxY
                let calloutHeight: CGFloat = 28 * 2 + 20 + 40 * 2
                
                if (btnBottomSpace - calloutHeight - 12 - 20) > 0 {
                    maker.top.equalTo(calloutButtonFrame.maxY + 12)
                } else {
                    maker.top.equalTo(calloutButtonFrame.minY - 12 - calloutHeight)
                }
                
            }
            
            view.addGestureRecognizer(bgTap)
            
            view.alpha = 0
            rx.viewDidAppear.take(1)
                .subscribe(onNext: { [weak self] _ in
                    
                    UIView.animate(withDuration: 0.25) {
                        self?.view.alpha = 1
                    }
                    
                })
                .disposed(by: bag)
        }
        
        private func dismiss() {
            
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.view.alpha = 0
            } completion: { [weak self] _ in
                self?.dismiss(animated: false)
            }
            
        }
        
    }
    
}
