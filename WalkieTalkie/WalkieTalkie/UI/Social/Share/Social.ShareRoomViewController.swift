//
//  Social.ShareRoomViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MessageUI
import SwiftyUserDefaults

extension Social {
    
    class ShareRoomViewController: WalkieTalkie.ViewController {
        
        /// room share
        private static var roomShareFriends = [Entity.UserProfile]()
        /// clear temp data
        class func clear() {
            Self.roomShareFriends = []
        }
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Social.FollowerCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var headerView = ShareHeaderView()
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        
        private var linkUrl = ""
        private var roomId = ""
        private var topicId = ""
        private var hiddened = false
        
        init(with linkUrl: String, roomId: String, topicId: String) {
            super.init(nibName: nil, bundle: nil)
            self.linkUrl = R.string.localizable.socialShareUrl(linkUrl)
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
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            Self.roomShareFriends = userList
        }
        
        private func setupLayout() {
            
            view.backgroundColor = UIColor(hex6: 0x222222)
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                maker.height.equalTo(500)
            }
            
            let line = UIView()
            line.backgroundColor = UIColor(hex6: 0xFFFFFF,alpha: 0.2)
            line.layer.masksToBounds = true
            line.layer.cornerRadius = 2
            view.addSubviews(views: line)
            line.snp.makeConstraints { (make) in
                make.top.equalTo(8)
                make.centerX.equalToSuperview()
                make.width.equalTo(36)
                make.height.equalTo(4)
            }
            
            headerView.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 195)
            tableView.tableHeaderView = headerView
            headerView.smsHandle = { [weak self] in
                guard let `self` = self else { return }
                self.smsAction()
            }
            headerView.copyLinkHandle = { [weak self] in
                guard let `self` = self else { return }
                self.copyLink()
            }
        }
    }
}
private extension Social.ShareRoomViewController {
    func loadData() {
        let users = Self.roomShareFriends
        if users.isEmpty {
            let removeBlock = view.raft.show(.loading)
            Request.inviteFriends(skipMs: 0)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let data = data else { return }
                    self?.userList = data.list ?? []
                    Self.roomShareFriends = self?.userList ?? []
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("inviteFriends error: \(error.localizedDescription)")
                }).disposed(by: bag)
        } else {
            userList = users
        }
    }
    
    func smsAction() {
        Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "sms")
        if MFMessageComposeViewController.canSendText() {
            let vc = MFMessageComposeViewController()
            vc.body = linkUrl
            vc.messageComposeDelegate = self
            self.present(vc, animated: true, completion: nil)
        } else {
            view.raft.autoShow(.text("Sorry, your device do not \nsupport message"))
        }
    }
    
    func copyLink() {
        Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "copy")
        linkUrl.copyToPasteboard()
        view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false, backColor: UIColor(hex6: 0x181818))
    }
}

extension Social.ShareRoomViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}
// MARK: - UITableView
extension Social.ShareRoomViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: Social.FollowerCell.self)
        if let user = userList.safe(indexPath.row) {
            cell.setCellDataForShare(with: user, roomId: roomId)
            cell.updateInviteData = { [weak self] (follow) in
                guard let `self` = self else { return }
                self.userList[indexPath.row].invited = follow
                Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: self.topicId), "invite")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = userList.safe(indexPath.row) {
            Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "profile")
            let vc = Social.ProfileViewController(with: user.uid)
            self.navigationController?.pushViewController(vc)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -15 && !hiddened {
            self.hideModal()
            hiddened = true
        }
    }
}

extension Social.ShareRoomViewController {
    
    private class ShareHeaderView: UIView {
        
        let bag = DisposeBag()
        
        var smsHandle:(()-> Void)?
        var copyLinkHandle:(()-> Void)?
        
        private lazy var smsBtn: LinkButton = {
            let btn = LinkButton(with: R.image.ac_room_share(), title: R.string.localizable.socialSms())
            return btn
        }()
        
        private lazy var copyLinkBtn:LinkButton = {
            let btn = LinkButton(with: R.image.ac_room_copylink(), title: R.string.localizable.socialCopyLink())
            return btn
        }()
        
        private lazy var inviteLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.text = R.string.localizable.socialInviteFriends()
            lb.textColor = .white
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubviews(views: smsBtn, copyLinkBtn, inviteLabel)
            
            smsBtn.snp.makeConstraints { (make) in
                make.left.equalTo(20)
                make.top.equalTo(40)
                make.width.equalTo(40)
                make.height.equalTo(68)
            }
            
            copyLinkBtn.snp.makeConstraints { (make) in
                make.left.equalTo(smsBtn.snp.right).offset(40)
                make.top.equalTo(40)
                make.width.equalTo(70)
                make.height.equalTo(68)
            }
            
            inviteLabel.snp.makeConstraints { (make) in
                make.left.equalTo(20)
                make.top.equalTo(smsBtn.snp.bottom).offset(40)
            }
            
            smsBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.smsHandle?()
                }).disposed(by: bag)
            
            copyLinkBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.copyLinkHandle?()
                }).disposed(by: bag)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private class LinkButton: UIButton {
        
        private lazy var iconImageV = UIImageView()
        
        private lazy var subtitleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = .white
            return lb
        }()
        
        init(with icon: UIImage?, title: String) {
            super.init(frame: .zero)
            
            addSubviews(views: iconImageV, subtitleLabel)
            iconImageV.snp.makeConstraints { (maker) in
                maker.top.centerX.equalToSuperview()
                maker.height.width.equalTo(40)
            }
            
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(iconImageV.snp.bottom).offset(5)
                maker.centerX.equalToSuperview()
            }
            
            iconImageV.image = icon
            subtitleLabel.text = title
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
}
extension Social.ShareRoomViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 500
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 20
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
