//
//  FansGroup.SelectGroupMemberViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/9.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup {
    
    class SelectGroupMemberViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            
            n.addSubview(cancelBtn)
            cancelBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().offset(-20)
                maker.centerY.equalToSuperview()
            }
            
            return n
        }()
        
        private lazy var cancelBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .disabled)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 24)
            btn.setTitle(R.string.localizable.toastCancel(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    
                    guard let `self` = self else { return }
                    
                    self.membersRelay.value.forEach({ (member) in
                        member.isSelected = false
                    })
                    self.membersRelay.accept(self.membersRelay.value)
                    self.selectedMembersRelay.accept([])
                })
                .disposed(by: bag)
            
            selectedMembersRelay.map { $0.count > 0 }
                .bind(to: btn.rx.isEnabled)
                .disposed(by: bag)
            
            return btn
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(MemberCell.self, forCellReuseIdentifier: NSStringFromClass(MemberCell.self))
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = 69
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            if #available(iOS 11.0, *) {
                tb.contentInsetAdjustmentBehavior = .never
            } else {
                // Fallback on earlier versions
                automaticallyAdjustsScrollViewInsets = false
            }
            tb.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 100, right: 0)
            return tb
        }()
        
        private lazy var bottomGradientView: FansGroup.Views.BottomGradientButton = {
            let v = FansGroup.Views.BottomGradientButton()
            
            let btn = v.button
            btn.setTitleColor(UIColor(hex6: 0xFB5858), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.backgroundColor = UIColor(hexString: "#2B2B2B")

            selectedMembersRelay.map { $0.count }
                .subscribe(onNext: { (count) in
                    btn.setTitle(R.string.localizable.amongChatGroupKickMemberButtonTitle("\(count)"), for: .normal)
                })
                .disposed(by: bag)
            
            selectedMembersRelay.map { $0.count > 0 }
                .bind(to: btn.rx.isEnabled)
                .disposed(by: bag)
            
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.kickOutSelected()
                })
                .disposed(by: bag)
            
            return v
        }()
        
        private let membersRelay = BehaviorRelay<[CellViewModel]>(value: [])
        private let selectedMembersRelay = BehaviorRelay<[CellViewModel]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupInfo: Entity.GroupInfo
        
        init(with groupInfo: Entity.GroupInfo) {
            self.groupInfo = groupInfo
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            fetchMembers()
        }
        
    }
    
}

extension FansGroup.SelectGroupMemberViewController: UITableViewDataSource {
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return membersRelay.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MemberCell.self), for: indexPath)
                
        if let memberCell = cell as? MemberCell,
           let member = membersRelay.value.safe(indexPath.row) {
            
            memberCell.bind(user: member)
            memberCell.selectHandler = { [weak self] in
                guard let `self` = self else {
                    return
                }
                member.isSelected = !member.isSelected
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.selectedMembersRelay.accept(self.membersRelay.value.filter({ $0.isSelected }))
            }
        }
        
        return cell
    }
    
}

extension FansGroup.SelectGroupMemberViewController: UITableViewDelegate {
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension FansGroup.SelectGroupMemberViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, tableView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        tableView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(navView.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        tableView.pullToLoadMore { [weak self] in
            self?.fetchMembers()
        }
    }
    
    private func setUpEvents() {
        membersRelay
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.reloadData()
            })
            .disposed(by: bag)
        
    }
    
    private func fetchMembers() {
        guard hasMoreData,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        Request.membersOfGroup(groupInfo.group.gid,
                               skipMs: membersRelay.value.last?.user.opTime ?? 0)
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
            })
            .subscribe(onSuccess: { [weak self] (memberList) in
                
                guard let `self` = self else {
                    return
                }
                var members = self.membersRelay.value
                members.append(contentsOf: memberList.list.map({ CellViewModel(user: $0) }))
                self.membersRelay.accept(members)
                self.hasMoreData = memberList.more
                self.tableView.endLoadMore(memberList.more)
            })
            .disposed(by: bag)
        
    }
    
    private func kickOutSelected() {
        
        let uids = selectedMembersRelay.value.map { $0.user.uid }
        
        guard uids.count > 0 else {
            return
        }
        
        let hudRemoval = self.view.raft.show(.loading)
        
        Request.kickMemberFromGroup(groupInfo.group.gid, uids: uids)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] _ in
                guard let `self` = self else { return }
                
                self.selectedMembersRelay.accept([])
                var members = self.membersRelay.value
                members.removeAll(where: { $0.isSelected })
                self.membersRelay.accept(members)
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
        
    }
}

extension FansGroup.SelectGroupMemberViewController {
    
    class MemberCell: UITableViewCell {
        
        private let bag = DisposeBag()
        
        private typealias UserView = AmongChat.Home.UserView
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
        
        private lazy var selectBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setImage(R.image.ac_group_unselected(), for: .normal)
            btn.setImage(R.image.ac_group_selected(), for: .selected)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.selectHandler?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        var selectHandler: (() -> Void)? = nil
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            selectionStyle = .none
            
            contentView.addSubviews(views: userView, selectBtn)
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(selectBtn.snp.leading).offset(-20)
            }
            
            selectBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
            }
        }
        
        func bind(user: CellViewModel) {
            userView.bind(profile: user.user)
            selectBtn.isSelected = user.isSelected
        }
        
    }
    
}

extension FansGroup.SelectGroupMemberViewController {
    
    class CellViewModel {
        
        let user: Entity.UserProfile
        
        var isSelected = false
        
        init(user: Entity.UserProfile) {
            self.user = user
        }
    }
    
}
