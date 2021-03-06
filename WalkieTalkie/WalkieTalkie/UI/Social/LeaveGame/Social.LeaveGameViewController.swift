//
//  LeaveGameViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
extension Social {
    
    class LeaveGameViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.navigationController?.popToRootViewController(animated: true)
                }).disposed(by: bag)
            btn.setImage(R.image.ac_profile_close(), for: .normal)
            let lb = n.titleLabel
            lb.text = R.string.localizable.socialExitChannel()
            return n
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Social.FollowerCell.self)
            tb.register(cellWithClass: NoDatacell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        private var roomId = ""
        private var topicId = ""
        
        override var screenName: Logger.Screen.Node.Start {
            return .exit_channel
        }
        
        init(with roomId: String, topicId: String) {
            super.init(nibName: nil, bundle: nil)
            self.roomId = roomId
            self.topicId = topicId
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
            Logger.Action.log(.room_exit_channel_imp)
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            view.addSubviews(views: navView)
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(navView.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            Request.endUsers(roomId: roomId)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let data = data else { return }
                    self?.userList = data.list ?? []
                    self?.tableView.endLoadMore(data.more ?? false)
                }, onError: { [weak self](error) in
                    removeBlock()
                    self?.addErrorView({ [weak self] in
                        self?.loadData()
                    })
                    cdPrint("Exit channel error: \(error.localizedDescription)")
                }).disposed(by: bag)
        }
    }
}

// MARK: - UITableView
extension Social.LeaveGameViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if userList.isEmpty {
            return 1
        }
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !userList.isEmpty {
            let cell = tableView.dequeueReusableCell(withClass: Social.FollowerCell.self)
            cell.configView(with: userList[indexPath.row], isFollowing: false, isSelf: false)
            cell.updateFollowData = { [weak self](follow) in
                guard let `self` = self else { return }
                self.userList[indexPath.row].isFollowed = follow
                Logger.Action.log(.room_exit_channel_clk, category: Logger.Action.Category(rawValue: self.topicId), "follow")
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withClass: NoDatacell.self)
            cell.setCellMeessage(R.string.localizable.errorNoTeammates())
            cell.updateCellUI()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if userList.isEmpty {
            return 500
        }
        return 69
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = userList.safe(indexPath.row) {
            Logger.Action.log(.room_exit_channel_clk, category: Logger.Action.Category(rawValue: topicId), "profile")
            let vc = Social.ProfileViewController(with: user.uid)
            self.navigationController?.pushViewController(vc)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        let lable = UILabel()
        v.addSubview(lable)
        lable.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalTo(-16.5)
        }
        lable.numberOfLines = 0
        lable.textColor = UIColor(hex6: 0x898989)
        lable.font = R.font.nunitoExtraBold(size: 16)
        lable.text = R.string.localizable.socialFollowTeammates()
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension Social.LeaveGameViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return Frame.Screen.height
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func containerCornerRadius() -> CGFloat {
        return 0
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
