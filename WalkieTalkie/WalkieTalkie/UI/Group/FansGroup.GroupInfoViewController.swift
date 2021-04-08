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
                maker.trailing.equalToSuperview().offset(-20)
                maker.centerY.equalToSuperview()
            }
            return n
        }()
        
        private lazy var settingBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_group_setting(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    
                })
                .disposed(by: bag)
            btn.isHidden = true
            return btn
        }()
        
        private lazy var groupHeaderView: GroupHeaderView = {
            let h = GroupHeaderView()
            h.frame = CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width, height: 254))
            h.leaveHandler = { [weak self] in
                self?.leaveGroup()
            }
            
            h.expandedHandler = { [weak self] in
                guard let `self` = self else { return }
                self.tableView.tableHeaderView?.frame.size = self.groupHeaderView.viewSize
                self.tableView.reloadData()
            }
            
            return h
        }()
        
        private var tableView: UITableView!
        
        private lazy var applyButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.amongChatGroupApplyToJoin(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.apply()
                })
                .disposed(by: bag)

            return btn
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = Social.ChooseGame.bottomGradientView()
            v.addSubviews(views: applyButton)
            applyButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(-33)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            v.isHidden = true
            return v
        }()
        
        private let groupId: String
        private var groupInfoViewModel: GroupViewModel? = nil {
            didSet {
                
                bottomGradientView.isHidden = !(groupInfoViewModel?.userStatus == .some(.applied) || groupInfoViewModel?.userStatus == .some(.none))
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
        }
        
    }
    
}

extension FansGroup.GroupInfoViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: groupHeaderView, navView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
        }
        
    }
        
    private func fetchInfo() {
        
        let hudRemoval = self.view.raft.show(.loading)
        Request.groupInfo(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { (info) in
                self.updateContent(info)
            })
            .disposed(by: bag)
    }
    
    private func leaveGroup() {
        let hudRemoval = self.view.raft.show(.loading)
        Request.leaveGroup(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
    }
    
    private func apply() {
        let hudRemoval = self.view.raft.show(.loading)
        Request.applyToJoinGroup(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (_) in
                self?.bottomGradientView.isHidden = true
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
                
                self.navView.snp.updateConstraints { (maker) in
                    maker.top.equalTo(self.topLayoutGuide.snp.bottom).offset(min(0, -distance / 3))
                }
                
                self.navView.alpha = 1 - distance / 49
                
            })
            .disposed(by: bag)

    }
}
