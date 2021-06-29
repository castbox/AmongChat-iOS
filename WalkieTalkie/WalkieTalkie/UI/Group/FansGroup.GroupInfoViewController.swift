//
//  FansGroup.GroupInfoViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDCAlertView

extension FansGroup {
    
    class GroupInfoViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatGroupInfo()
            
            n.addSubview(settingBtn)
            settingBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
            }
            return n
        }()
        
        private lazy var settingBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_group_setting(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.gotoEdit()
                })
                .disposed(by: bag)
            btn.isHidden = true
            return btn
        }()
        
        private lazy var groupHeaderView: GroupHeaderView = {
            let h = GroupHeaderView()
            h.frame = CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width, height: 254))
            h.leaveHandler = { [weak self] in
                Logger.Action.log(.group_info_clk, categoryValue: self?.groupInfoViewModel?.groupInfo.group.topicId, "leave_confirm")
                self?.leaveGroup()
            }
            
            h.expandedHandler = { [weak self] in
                guard let `self` = self else { return }
                self.tableView.tableHeaderView?.frame.size = self.groupHeaderView.viewSize
                self.tableView.reloadData()
            }
            
            return h
        }()
        
        private var tableView: UITableView! {
            didSet {
                tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 134, right: 0)
            }
        }
        
        private lazy var bottomGradientView: FansGroup.Views.BottomGradientButton = {
            let v = FansGroup.Views.BottomGradientButton()
            v.button.setTitle(R.string.localizable.amongChatGroupApplyToJoin(), for: .normal)
            v.button.setTitle(R.string.localizable.amongChatGroupApplied(), for: .disabled)
            v.button.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    Logger.Action.log(.group_info_clk, categoryValue:  self?.groupInfoViewModel?.groupInfo.group.topicId, "apply")
                    self?.apply()
                })
                .disposed(by: bag)
            v.button.isHidden = true
            v.isHidden = true
            return v
        }()
        
        private let groupId: String
        private var groupInfoViewModel: GroupViewModel? = nil {
            didSet {
                
                bottomGradientView.isHidden = !(groupInfoViewModel?.userStatus == .some(.applied) || groupInfoViewModel?.userStatus == .some(.none))
                bottomGradientView.button.isEnabled = groupInfoViewModel?.userStatus == .some(.none)
                bottomGradientView.button.isHidden = false
                settingBtn.isHidden = !(groupInfoViewModel?.userStatus == .some(.admin) || groupInfoViewModel?.userStatus == .some(.owner))
                
            }
        }
        
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
            fetchInfo()
            setUpEvents()
        }
        
    }
    
}

extension FansGroup.GroupInfoViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: groupHeaderView, navView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
    }
    
    private func setUpEvents() {
        
            FansGroup.GroupUpdateNotification.groupUpdated
            .subscribe(onNext: { [weak self] action, group in
                guard let `self` = self else { return }
                
                switch action {
                case .added:
                    ()
                
                case .removed:
                    guard group.gid == self.groupId else {
                        return
                    }
                    self.navigationController?.viewControllers.removeAll(where: { $0 === self })

                case .updated:
                    ()
                }
            })
            .disposed(by: bag)
        
    }
        
    private func fetchInfo() {
        
        let hudRemoval = self.view.raft.show(.loading)
        Request.groupInfo(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (info) in
                self?.updateContent(info)
            })
            .disposed(by: bag)
    }
    
    private func leaveGroup() {
        
        let messageAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.amongChatGroupLeaveTip(),
                                                                 attributes: [
                                                                    NSAttributedString.Key.font : R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: UIColor.white
                                                                 ])
        
        let cancelAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.toastCancel(),
                                                                attributes: [
                                                                    NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: "#6C6C6C".color()
                                                                ])
        
        let confirmAttr = NSAttributedString(string: R.string.localizable.roomLeave(),
                                             attributes: [
                                                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                .foregroundColor: "#FB5858".color()
                                             ])
        
        let alertVC = AlertController(attributedTitle: nil, attributedMessage: messageAttr, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alertVC.visualStyle = visualStyle
        
        alertVC.addAction(AlertAction(attributedTitle: cancelAttr, style: .normal))
        
        alertVC.addAction(AlertAction(attributedTitle: confirmAttr, style: .normal, handler: { [weak self] _ in
            guard let `self` = self else { return }
            
            let hudRemoval: (() -> Void)? = self.view.raft.show(.loading, userInteractionEnabled: false)
            
            Request.leaveGroup(self.groupId)
                .do(onDispose: {
                    hudRemoval?()
                })
                .subscribe(onSuccess: { [weak self] (_) in
                    if let group = self?.groupInfoViewModel?.groupInfo.group {
                        FansGroup.GroupUpdateNotification.publishNotificationOf(group: group, action: .removed)
                    }
                    self?.navigationController?.popViewController(animated: true)
                })
                .disposed(by: self.bag)
            
        })
        )
        
        alertVC.view.backgroundColor = UIColor.black.alpha(0.6)
        alertVC.present()
        
    }
    
    private func apply() {
        let hudRemoval = self.view.raft.show(.loading)
        Request.applyToJoinGroup(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (_) in
                self?.bottomGradientView.button.isEnabled = false
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
    }
    
    private func updateContent(_ groupInfo: Entity.GroupInfo) {
        
        let g = GroupViewModel(groupInfo: groupInfo)
        groupInfoViewModel = g
        
        let listVC = FansGroup.GroupMemberListViewController(with: groupInfo)
        
        addChild(listVC)
        view.addSubview(listVC.view)
        listVC.view.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        view.sendSubviewToBack(listVC.view)
        listVC.didMove(toParent: self)
        
        tableView = listVC.tableView
        
        groupHeaderView.bindViewModel(g)
        groupHeaderView.frame.size = groupHeaderView.viewSize
        
        tableView.tableHeaderView = groupHeaderView
        tableView.reloadData()
        
        tableView.rx.contentOffset
            .subscribe(onNext: { [weak self] (point) in
                
                guard let `self` = self else { return }
                
                let distance = point.y
                
                self.groupHeaderView.enlargeTopGbHeight(extraHeight: -distance)
                                
                self.navView.backgroundView.alpha = distance / NavigationBar.barHeight
                self.navView.backgroundView.isHidden = distance <= 0
            })
            .disposed(by: bag)

    }
    
    private func gotoEdit() {
        
        guard let info = groupInfoViewModel?.groupInfo else {
            return
        }
        
        let editVC = FansGroup.GroupEditViewController(groupInfo: info)
        navigationController?.pushViewController(editVC, animated: true)
    }
}
