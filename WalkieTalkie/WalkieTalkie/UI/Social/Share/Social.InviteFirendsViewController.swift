//
//  Social.InviteFirendsViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 20/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MessageUI
import SwiftyUserDefaults
import SwiftyContacts
import HWPanModal

extension Social {
    class InviteFirendsViewController: WalkieTalkie.ViewController {
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Social.ContactCell.self)
            tb.register(cellWithClass: Social.EnableContactsCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var headerView = ShareHeaderView()
        private lazy var viewModel = InviteFirendsViewModel()
        
        private var items: [InviteFirendsViewModel.Item] = [] {
            didSet {
                if items.count == 1,
                   items.first?.group == .contacts,
                   items.first?.userLsit.isEmpty == true {
                    addNoDataView(R.string.localizable.contactsEmpty())
                } else {
                    removeNoDataView()
                }
                tableView.reloadData()
            }
        }
        
        private var hiddened = false
        private let linkUrl = R.string.localizable.shareAppContent()
        
//        init() {
//            super.init(nibName: nil, bundle: nil)
//        }
        
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
            Logger.Action.log(.contact_imp)

        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
//            ShareRoomViewModel.roomShareItems = items
        }
        
        private func setupLayout() {
            
            view.backgroundColor = UIColor(hex6: 0x222222)
            view.addSubviews(views: tableView, headerView)
            tableView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(headerView.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            headerView.snp.makeConstraints { maker in
                maker.top.leading.trailing.equalToSuperview()
                maker.height.equalTo(159)
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
            
            
//            headerView.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 159)
//            tableView = headerView
            headerView.smsHandle = { [weak self] in
                guard let `self` = self else { return }
                self.sendSMS(body: self.linkUrl)
                Logger.Action.log(.contact_clk, category: .sms)
            }
            headerView.copyLinkHandle = { [weak self] in
                guard let `self` = self else { return }
                self.copyLink()
                Logger.Action.log(.contact_clk, category: .copy)
            }
            headerView.shareLinkHandle = { [weak self] in
                guard let `self` = self else { return }
                self.shareApp()
                Logger.Action.log(.contact_clk, category: .share)
            }
        }
    }
}
private extension Social.InviteFirendsViewController {
    func updateEventForContactAuthorizationStatus() {
        //get access
        SwiftyContacts.authorizationStatus { [weak self] status in
            switch status {
            case .authorized:
                self?.viewModel.updateContacts()
            case .denied, .restricted:
                self?.showContactsAccessDeniedAlert()
            case .notDetermined:
                self?.requestContactsAccess()
            @unknown default:
                ()
            }
        }
    }
    
    func requestContactsAccess() {
        SwiftyContacts.requestAccess { [weak self] result in
            if result {
                self?.viewModel.updateContacts()
                Logger.Action.log(.contact_permission_enable)
            }
            //
        }
    }
    
    
    func showContactsAccessDeniedAlert() {
        showAmongAlert(title: nil, message: R.string.localizable.socialContactDeniedTitle(), cancelTitle: R.string.localizable.toastCancel(), confirmTitle: R.string.localizable.bigEnable(), cancelAction: nil) {
            Self.openAppSystemSetting()
        }
    }
    
    
    
    func loadData() {
        let offset = (Frame.Screen.height - view.height) / 2
        let removeBlock = view.raft.show(.loading, userInteractionEnabled: false, offset: CGPoint(x: 0, y: -offset))
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
        
//        viewModel.loadData()
        
        SwiftyContacts.authorizationStatus { [weak self] status in
            switch status {
            case .denied, .restricted, .notDetermined:
                self?.viewModel.showFindCell()
            case .authorized:
                self?.viewModel.updateContacts()
            @unknown default:
                ()
            }
        }
    }
    
    func copyLink() {
//        Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "copy")
        linkUrl.copyToPasteboardWithHaptic()
        view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false, backColor: UIColor(hex6: 0x181818))
    }
    
    func shareApp() {
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }

        self.view.isUserInteractionEnabled = false
        ShareManager.default.showActivity(viewController: self) { () in
            removeBlock()
        }
    }
}

// MARK: - UITableView
extension Social.InviteFirendsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let item = items.safe(section) else {
            return 0
        }
        if item.group == .find {
            return 1
        }
        return item.userLsit.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: Social.ContactCell.self)
        if let item = items.safe(indexPath.section) {
            if item.group == .find {
                let cell = tableView.dequeueReusableCell(withClass: Social.EnableContactsCell.self)
                cell.enableHandler = { [weak self] in
                    Logger.Action.log(.contact_clk, category: .go)
                    self?.updateEventForContactAuthorizationStatus()
                }
                return cell
            } else if let user = item.userLsit.safe(indexPath.row) {
                cell.bind(viewModel: user) { [weak self] in
                    guard let `self` = self else { return }
                    self.sendSMS(to: user.phone, body: self.linkUrl)
                    Logger.Action.log(.contact_clk, category: .invite)
                }
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
//            Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "profile")
//            let vc = Social.ProfileViewController(with: user.uid)
//            self.navigationController?.pushViewController(vc)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let item = items.safe(section), item.group == .contacts else {
            return nil
        }
        let v = UIView()
        v.backgroundColor = UIColor(hex6: 0x222222)
        let lable = UILabel()
        v.addSubview(lable)
        lable.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(20)
        }
        lable.textColor = .white
        lable.font = R.font.nunitoExtraBold(size: 20)
        lable.adjustsFontSizeToFitWidth = true
        lable.text = item.group.title
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let item = items.safe(section), item.group == .contacts else {
            return 0
        }
        return 53
//        guard let item = items.safe(section) else {
//            return 0
//        }
//        if item.group == .find {
//            return 0
//        } else if item.userLsit.isEmpty {
//            return 53
//        }
//        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
}

extension Social.InviteFirendsViewController {
    
    private class ShareHeaderView: UIView {
        
        let bag = DisposeBag()
        var smsHandle: (()-> Void)?
        var copyLinkHandle: (()-> Void)?
        var shareLinkHandle: (()-> Void)?
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.text = R.string.localizable.socialAddNew()
            lb.textColor = .white
            return lb
        }()
        
        private lazy var smsBtn: LinkButton = {
            let btn = LinkButton(with: R.image.ac_room_share(), title: R.string.localizable.socialSms())
            return btn
        }()
        
        private lazy var copyLinkBtn: LinkButton = {
            let btn = LinkButton(with: R.image.ac_room_copylink(), title: R.string.localizable.socialCopyLink())
            return btn
        }()
        
        private lazy var shareLinkBtn: LinkButton = {
            let btn = LinkButton(with: R.image.icon_social_share_link(), title: R.string.localizable.socialShareLink())
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
            
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.top.equalTo(30.5)
                make.centerX.equalToSuperview()
            }

                        
            if MFMessageComposeViewController.canSendText() {
                addSubviews(views: smsBtn, copyLinkBtn)

                smsBtn.snp.makeConstraints { (make) in
                    make.left.equalTo(20)
                    make.top.equalTo(72)
                    make.width.equalTo(40)
                    make.height.equalTo(68)
                }
                
                copyLinkBtn.snp.makeConstraints { (make) in
                    make.left.equalTo(smsBtn.snp.right).offset(40)
                    make.top.equalTo(72)
                    make.width.equalTo(70)
                    make.height.equalTo(68)
                }
            } else {
                addSubviews(views: copyLinkBtn)

                copyLinkBtn.snp.makeConstraints { (make) in
                    make.left.equalTo(20)
                    make.top.equalTo(72)
                    make.width.equalTo(40)
                    make.height.equalTo(68)
                }
            }
            
            let lineView = UIView()
            lineView.backgroundColor = UIColor.white.alpha(0.08)
            addSubviews(views: lineView, shareLinkBtn)
            
            shareLinkBtn.snp.makeConstraints { (make) in
                make.left.equalTo(copyLinkBtn.snp.right).offset(40)
                make.centerY.equalTo(copyLinkBtn)
                make.width.equalTo(70)
                make.height.equalTo(68)
            }
            
            lineView.snp.makeConstraints { maker in
                maker.left.right.bottom.equalToSuperview()
                maker.height.equalTo(1)
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
            
            shareLinkBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.shareLinkHandle?()
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

extension Social {
    class ContactCell: TableViewCell {
        
        private lazy var userView: AmongChat.Home.UserView = {
            let v = AmongChat.Home.UserView()
            return v
        }()
                
        private lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.socialInvite(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return btn
        }()
        
        private var joinDisposable: Disposable? = nil
        
        private var lockedDisposable: Disposable? = nil
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = "#222222".color()
            selectionStyle = .none

            contentView.addSubviews(views: userView, joinBtn)
                        
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(buttonLayout.snp.leading).offset(-20)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
        }
        
        func bind(viewModel: Entity.ContactFriend,
                  onJoin: @escaping () -> Void) {
            userView.bind(viewModel: viewModel) {
                
            }
            
            joinDisposable?.dispose()
            joinDisposable = joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    onJoin()
                })
        }
        
    }
    
    class EnableContactsCell: TableViewCell {
        
        var enableHandler: (() -> Void)?
        
        let bag = DisposeBag()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView(image: R.image.icon_social_find_contaccts())
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var usernameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.text = R.string.localizable.socialInviteContactMobile()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.numberOfLines = 0
            lb.textColor = .white
            return lb
        }()
        
        private lazy var followBtn: UIButton = {
            let btn = UIButton()
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitle(R.string.localizable.bigGo(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.titleLabel?.lineBreakMode = .byTruncatingMiddle
            return btn
        }()
        
        private var userInfo: Entity.UserProfile!
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
        }
        
        private func setupLayout() {
            selectionStyle = .none
            backgroundColor = "#222222".color()
            
            contentView.addSubviews(views: avatarIV, usernameLabel, followBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(40)
            }
            
            usernameLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(avatarIV.snp.trailing).offset(12)
                maker.trailing.equalTo(followBtn.snp.leading).offset(-12)
                maker.centerY.equalTo(avatarIV.snp.centerY)
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.width.equalTo(90)
                maker.height.equalTo(32)
                maker.trailing.equalTo(-20)
                maker.centerY.equalTo(avatarIV.snp.centerY)
            }
            
            followBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    self.enableHandler?()
                }).disposed(by: bag)
        }
        
        
        func setCellDataForShare(with model: Entity.UserProfile) {
            
            self.userInfo = model
            
            setUIForShare()
            avatarIV.setAvatarImage(with: model.pictureUrl)
            usernameLabel.text = model.name
        }
        
        private func setUIForShare() {
            followBtn.setTitleColor(.black, for: .normal)
            followBtn.setTitle(R.string.localizable.bigGo(), for: .normal)
            followBtn.snp.updateConstraints { (maker) in
                maker.width.equalTo(78)
            }
        }
    }
}

//extension Social.InviteFirendsViewController: Modalable {
//
//    func style() -> Modal.Style {
//        return .customHeight
//    }
//
//    func height() -> CGFloat {
//        return 500
//    }
//
//    func modalPresentationStyle() -> UIModalPresentationStyle {
//        return .overCurrentContext
//    }
//
//    func containerCornerRadius() -> CGFloat {
//        return 20
//    }
//
//    func coverAlpha() -> CGFloat {
//        return 0.5
//    }
//
//    func canAutoDismiss() -> Bool {
//        return true
//    }
//}

extension Social.InviteFirendsViewController {
    
    override func longFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .topInset, height: 0)
    }

    override func shortFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: Frame.Scale.height(500))
    }

    override func panScrollable() -> UIScrollView? {
        return tableView
    }

    override func allowsExtendedPanScrolling() -> Bool {
        return true
    }
    
    override func cornerRadius() -> CGFloat {
        return 20
    }

    override func showDragIndicator() -> Bool {
        return false
    }
    
}
