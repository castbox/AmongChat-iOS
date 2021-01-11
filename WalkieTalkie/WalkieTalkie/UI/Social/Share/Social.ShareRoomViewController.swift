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
    
    class ShareRoomViewModel {
        public var dataSourceReplay = BehaviorRelay<[Item]>(value: [])
        
        private var items: [Item] = [] {
            didSet {
                dataSourceReplay.accept(items)
            }
        }
        
        private var frientds: [Entity.UserProfile] = []
        
        /// room share
        static var roomShareItems: [Item] = []
        private let bag = DisposeBag()
        
        
        func loadData() {
            let users = Self.roomShareItems
            if users.isEmpty {
                requestFriends()
            } else {
                items = users
            }
        }
        
        func requestFriends(skipMs: Double = 0) {
            Request.inviteFriends(skipMs: skipMs)
                .subscribe(onSuccess: { [weak self](data) in
                    guard let `self` = self, let data = data else {
                        return
                    }
                    self.frientds.append(contentsOf: data.list ?? [])
                    self.append(self.frientds, group: .friends)
                    guard data.more == true, let lastOpTime = data.list?.last?.opTime else {
                        self.requestStranger()
                        return
                    }
                    self.requestFriends(skipMs: lastOpTime)
                }, onError: { (error) in
                    self.requestStranger()
                    cdPrint("inviteFriends error: \(error.localizedDescription)")
                }).disposed(by: bag)
        }
        
        func requestStranger() {
            Request.onlineStrangers()
                .subscribe(onSuccess: { [weak self](data) in
                    guard let data = data else { return }
                    self?.append(data.list, group: .stranger)
                }, onError: { (error) in
                    cdPrint("inviteFriends error: \(error.localizedDescription)")
                }).disposed(by: bag)
        }
        
        func append(_ list: [Entity.UserProfile]?, group: Item.Group) {
            guard let list = list else {
                return
            }
            var items = self.items.filter { $0.group != group }
            items.append(Item(userLsit: list, group: group))
            self.items = items.sorted { (old, previous) -> Bool in
                old.group.rawValue < previous.group.rawValue
            }
            if self.items.count == 2 {
                Self.roomShareItems = self.items
            }
        }
        
        /// clear temp data
        class func clear() {
            Self.roomShareItems = []
        }
    }
    
    class ShareRoomViewController: WalkieTalkie.ViewController {
        
        /// clear temp data
        class func clear() {
            ShareRoomViewModel.clear()
        }
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Social.FollowerCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var headerView = ShareHeaderView()
        private lazy var viewModel = ShareRoomViewModel()
        
        private var items: [ShareRoomViewModel.Item] = [] {
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
            ShareRoomViewModel.roomShareItems = items
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
            
            headerView.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 146)
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
        let removeBlock = view.raft.show(.loading)
        viewModel.dataSourceReplay
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self](data) in
                removeBlock()
                self?.items = data
            }, onError: { (error) in
                removeBlock()
                cdPrint("inviteFriends error: \(error.localizedDescription)")
            })
            .disposed(by: bag)
        
        viewModel.loadData()
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
        linkUrl.copyToPasteboardWithHaptic()
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.safe(section)?.userLsit.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: Social.FollowerCell.self)
        if let item = items.safe(indexPath.section), let user = item.userLsit.safe(indexPath.row) {
            cell.setCellDataForShare(with: user, roomId: roomId, isStranger: item.group == .stranger)
            cell.updateInviteData = { [weak self] (follow) in
                guard let `self` = self else { return }
                //                user.invited = follow
                self.items[indexPath.section].userLsit[indexPath.row].invited = follow
                //                self.userList[indexPath.row].invited = follow
                Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: self.topicId), item.group == .friends ? "invite" : "invite_stranger")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 69
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let user = items.safe(indexPath.section)?.userLsit.safe(indexPath.row) {
            Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "profile")
            let vc = Social.ProfileViewController(with: user.uid)
            self.navigationController?.pushViewController(vc)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let item = items.safe(section), !item.userLsit.isEmpty else {
            return nil
        }
        let v = UIView()
        let lable = UILabel()
        v.addSubview(lable)
        lable.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalTo(-2.5)
        }
        lable.textColor = .white
        lable.font = R.font.nunitoExtraBold(size: 20)
        lable.adjustsFontSizeToFitWidth = true
        lable.text = item.group.title
        lable.adjustsFontSizeToFitWidth = true
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 29.5
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -75 && !hiddened {
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
        
        //        private lazy var inviteLabel: WalkieLabel = {
        //            let lb = WalkieLabel()
        //            lb.font = R.font.nunitoExtraBold(size: 20)
        //            lb.text = R.string.localizable.socialInviteFriends()
        //            lb.textColor = .white
        //            return lb
        //        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
                        
            if MFMessageComposeViewController.canSendText() {
                addSubviews(views: smsBtn, copyLinkBtn)

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
            } else {
                addSubviews(views: copyLinkBtn)

                copyLinkBtn.snp.makeConstraints { (make) in
                    make.left.equalTo(20)
                    make.top.equalTo(40)
                    make.width.equalTo(40)
                    make.height.equalTo(68)
                }

            }
            //            inviteLabel.snp.makeConstraints { (make) in
            //                make.left.equalTo(20)
            //                make.top.equalTo(smsBtn.snp.bottom).offset(40)
            //            }
            
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

extension Social.ShareRoomViewModel {
    struct Item {
        enum Group: Int {
            case friends
            case stranger
        }
        
        var userLsit: [Entity.UserProfile]
        let group: Group
        
    }
    
}

extension Social.ShareRoomViewModel.Item.Group {
    var title: String {
        switch self {
        case .friends:
            return R.string.localizable.socialInviteFriends()
        case .stranger:
            return R.string.localizable.socialInvitePlayWith()
        }
    }
}
