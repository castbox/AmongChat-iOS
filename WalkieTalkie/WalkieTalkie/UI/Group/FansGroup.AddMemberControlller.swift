//
//  FansGroup.AddMemberControlller.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/31.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension FansGroup {
    
    class AddMemberController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.isHidden = true
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
        
        private typealias ShareHeaderView = Social.InviteFirendsViewController.ShareHeaderView
        private lazy var headerView = ShareHeaderView()
        
        private lazy var doneButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.profileDone(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    
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
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
        }
    }
    
}

extension FansGroup.AddMemberController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, headerView, tableView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        headerView.snp.makeConstraints { maker in
            maker.top.equalTo(navView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(159)
        }
        
        tableView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(headerView.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
        }
        
        let footer = UIView()
        footer.frame = CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width, height: 134))
        tableView.tableFooterView = footer
    }
}

extension FansGroup.AddMemberController: UITableViewDataSource {
    
    // MARK: - UITableView Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MemberCell.self), for: indexPath)
        return cell
    }
}
