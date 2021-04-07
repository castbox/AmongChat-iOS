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
    
    class AddMemberController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popToRootViewController(animated: true)
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatGroupAddMembers()
            return n
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.register(MemberCell.self, forCellReuseIdentifier: NSStringFromClass(MemberCell.self))
            tb.dataSource = self
            tb.rowHeight = 70
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var smsBtn: ShareButton = {
            let btn = ShareButton(with: R.image.ac_room_share(), title: R.string.localizable.socialSms())
            btn.tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var snapchatBtn: ShareButton = {
            let btn = ShareButton(with: R.image.ac_room_share_sn(), title: "Snapchat")
            btn.tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var copyLinkBtn: ShareButton = {
            let btn = ShareButton(with: R.image.ac_room_copylink(), title: R.string.localizable.socialCopyLink())
            btn.tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var shareLinkBtn: ShareButton = {
            let btn = ShareButton(with: R.image.icon_social_share_link(), title: R.string.localizable.socialShareLink())
            btn.tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var shareView: UIStackView = {
            let v = UIStackView()
            v.axis = .horizontal
            v.spacing = 0
            v.distribution = .fillEqually
            
            let btns: [UIView]
            
            if MFMessageComposeViewController.canSendText() {
                btns = [smsBtn, snapchatBtn, copyLinkBtn, shareLinkBtn]
            } else {
                btns = [snapchatBtn, copyLinkBtn, shareLinkBtn]
            }
            v.addArrangedSubviews(btns)
            btns.forEach { (v) in
                v.snp.makeConstraints { (maker) in
                    maker.width.equalTo(80)
                    maker.height.equalTo(67)
                }
            }
            v.backgroundColor = .clear
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
                    self?.navigationController?.popToRootViewController(animated: true)
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
        
        private let membersRelay = BehaviorRelay<[MemeberViewModel]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupId: String
                
        init(groupId: String) {
            self.groupId = groupId
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
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        view.addSubviews(views: navView, shareView, tableView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        shareView.snp.makeConstraints { maker in
            maker.top.equalTo(navView.snp.bottom).offset(24)
            maker.leading.equalToSuperview()
            maker.trailing.lessThanOrEqualToSuperview()
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
            .subscribe(onSuccess: { [weak self] (_) in
            })
            .disposed(by: bag)
        
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
                      }, onAvatarTap: {
                        
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
