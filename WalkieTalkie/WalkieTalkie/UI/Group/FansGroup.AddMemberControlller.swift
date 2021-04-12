//
//  FansGroup.AddMemberControlller.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/31.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MessageUI

extension FansGroup {
    
    class AddMemberController: WalkieTalkie.ViewController, GestureBackable {
        
        var isEnableScreenEdgeGesture: Bool = true
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatGroupAddMembers()
            return n
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(MemberCell.self, forCellReuseIdentifier: NSStringFromClass(MemberCell.self))
            tb.dataSource = self
            tb.rowHeight = 70
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            tb.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 100, right: 0)
            return tb
        }()
        
        private lazy var shareView: FansGroup.Views.ShareBar = {
            let v = FansGroup.Views.ShareBar()
            return v
        }()
        
        private lazy var doneButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.profileDone(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    if let done = self?.doneHandler {
                        done()
                    } else {
                        self?.navigationController?.popViewController(animated: true)
                    }
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = Social.ChooseGame.bottomGradientView()
            v.addSubviews(views: doneButton)
            doneButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(-33)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            return v
        }()
        
        private var shareUrl: String {
            return "https://among.chat/group?gid=\(groupId)"
        }
        
        private var shareText: String {
            return R.string.localizable.amongChatGroupShareContent(Settings.shared.amongChatUserProfile.value?.name ?? "",
                                                                   groupName,
                                                                   shareUrl)
        }
        
        private var groupName: String {
            return groupEntity.name
        }
        
        private var groupCover: String? {
            return groupEntity.cover
        }
        
        private let membersRelay = BehaviorRelay<[MemeberViewModel]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupId: String
        private let groupEntity: Entity.Group
        private let newAddedMember = PublishSubject<MemeberViewModel>()
        
        var doneHandler: (() -> Void)? = nil
        
        var newAddedMemberObservable: Observable<Entity.UserProfile> {
            return newAddedMember.map { $0.member }.asObservable()
        }
        
        init(groupId: String, _ group: Entity.Group) {
            self.groupId = groupId
            groupEntity = group
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            loadData()
        }
    }
    
}

extension FansGroup.AddMemberController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, shareView, tableView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        shareView.snp.makeConstraints { maker in
            maker.top.equalTo(navView.snp.bottom).offset(24)
            maker.leading.trailing.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(shareView.snp.bottom).offset(10)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
        }
        
        tableView.pullToLoadMore { [weak self] in
            self?.loadData()
        }
    }
    
    private func setUpEvents() {
        membersRelay
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.reloadData()
            })
            .disposed(by: bag)
        
        shareView.selectedSourceObservable
            .subscribe(onNext: { [weak self] (source) in
                
                guard let `self` = self else { return }
                
                switch source {
                case .sms:
                    self.sendSMS(body: self.shareText)
                    
                case .snapchat:
                    self.shareSnapchat()
                    
                case .copyLink:
                    self.copyLink()
                    
                case .shareLink:
                    self.shareLink()
                    
                }
            })
            .disposed(by: bag)
    }
    
    private func loadData() {
        
        guard hasMoreData,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        Request.availableFollowersToAddToGroup(groupId: groupId,
                                               skipMs: membersRelay.value.last?.member.opTime ?? 0)
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
            })
            .subscribe(onSuccess: { [weak self] (followers) in
                
                guard let `self` = self else {
                    return
                }
                var members = self.membersRelay.value
                members.append(contentsOf: followers.list.map({ MemeberViewModel(member: $0)}))
                self.membersRelay.accept(members)
                self.hasMoreData = followers.more
                self.tableView.endLoadMore(followers.more)
            })
            .disposed(by: bag)
    }
    
    private func addMember(_ member: MemeberViewModel, at indexPath: IndexPath) {
        
        member.add()
        tableView.reloadRows(at: [indexPath], with: .none)
        
        Request.addMember(member.member.uid, to: groupId)
            .subscribe(onSuccess: { [weak self] (success) in
                guard success else { return }
                self?.newAddedMember.onNext(member)
            })
            .disposed(by: bag)
        
    }
    
    private func shareSnapchat() {
        
        let removeHandler = view.raft.show(.loading)
        
        let content = ShareManager.Content(type: .group(groupCover), targetType: .snapchat, content: R.string.localizable.shareApp(), url: self.shareUrl)
        ShareManager.default.share(with: content, .snapchat, viewController: self) {
            removeHandler()
        }
    }
    
    private func copyLink() {
        shareText.copyToPasteboardWithHaptic()
    }
    
    private func shareLink() {
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        
        self.view.isUserInteractionEnabled = false
        ShareManager.default.showActivity(items: [shareText], viewController: self) { () in
            removeBlock()
        }
    }
    
}

extension FansGroup.AddMemberController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return membersRelay.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MemberCell.self), for: indexPath)
        if let cell = cell as? MemberCell,
           let user = membersRelay.value.safe(indexPath.row) {
            cell.bind(viewModel: user,
                      onAdd: { [weak self] in
                        self?.addMember(user, at: indexPath)
                      })
        }
        return cell
    }
}

extension FansGroup.AddMemberController {
    
    class MemeberViewModel {
        
        private(set) var member: Entity.UserProfile
        
        init(member: Entity.UserProfile) {
            self.member = member
        }
        
        var inGroup: Bool {
            return member.inGroup ?? false
        }
        
        func add() {
            member.inGroup = true
        }
        
        func remove() {
            member.inGroup = false
        }
    }
}
