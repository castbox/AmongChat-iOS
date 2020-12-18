//
//  AmongChat.Room.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
//import MoPub

extension AmongChat.Room {
    enum EditType {
        case message
        case amongSetup
        case robloxSetup
        case nickName
        case chillingSetup
    }
}

typealias RoomEditType = AmongChat.Room.EditType

extension AmongChat.Room {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private typealias UserCell = AmongChat.Room.UserCell
        private typealias ActionModal = ChannelUserListController.ActionModal
        
        private var room: Entity.Room
        private let viewModel: ViewModel

//        private let viewModel: ViewModel
        private var topBar: AmongChatRoomTopBar!
        private var configView: AmongChatRoomConfigView!
        private var amongInputCodeView: AmongInputCodeView!
        private var inputNotesView: AmongInputNotesView!
        private var nickNameInputView: AmongInputNickNameView!
        private var bottomBar: AmongRoomBottomBar!
        private var toolView: AmongRoomToolView!
        private var editType: AmongChat.Room.EditType = .message {
            didSet {
                switch editType {
                case .amongSetup:
                    self.view.bringSubviewToFront(amongInputCodeView)
                    amongInputCodeView.becomeFirstResponder()
                case .nickName:
                    self.view.bringSubviewToFront(nickNameInputView)
                    nickNameInputView.becomeFirstResponder()
                case .chillingSetup:
                    self.view.bringSubviewToFront(inputNotesView)
                    inputNotesView.show(with: room)
                default:
                    messageInputField.becomeFirstResponder()
                }
            }
        }
        
        private var dataSource: [Int: Entity.RoomUser] = [:] {
            didSet {
                userCollectionView.reloadData()
            }
        }
        
        private let fixedListLength = Int(10)
        private var messageListDataSource: [ChatRoomMessage] = [] {
            didSet {
                messageListTableView.reloadData()
                mainQueueDispatchAsync(after: 0.2) { [weak self] in
                    if self?.messageListTableView.contentSize.height ?? 0 > self?.messageListTableView.frame.size.height ?? 0 {
                        self?.messageListTableView.scrollToBottom()
                    }
                }
            }
        }

        private lazy var bgView: UIView = {
            let v = UIView()
            let ship = UIImageView(image: R.image.space_ship_bg())
            ship.contentMode = .scaleAspectFit
            let star = UIImageView(image: R.image.star_bg())
            let mask = UIView()
            mask.backgroundColor = UIColor.black.alpha(0.5)
            v.addSubviews(views: star, ship, mask)
            star.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            ship.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            mask.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }()
        
//        private lazy var copyNameBtn: UIView = {
//            let v = UIView()
//
//            let tapGR = UITapGestureRecognizer(target: self, action: #selector(onCopyNameBtn))
//            v.addGestureRecognizer(tapGR)
//
//            v.backgroundColor = UIColor.white.alpha(0.2)
//            v.layer.cornerRadius = 15
//
//            let hashSymbol: UILabel = {
//                let lb = UILabel()
//                lb.font = R.font.blackOpsOneRegular(size: 20)
//                lb.textColor = UIColor.white.alpha(0.5)
//                lb.text = "#"
//                return lb
//            }()
//
//            let nameLabel: UILabel = {
//                let lb = UILabel()
//                lb.font = R.font.nunitoRegular(size: 14)
//                lb.textColor = .white
//                lb.text = room.roomId
//                return lb
//            }()
//
//            let icon = UIImageView(image: R.image.btn_room_copy())
//            icon.contentMode = .scaleAspectFill
//            icon.backgroundColor = .clear
//
//            v.addSubviews(views: hashSymbol, nameLabel, icon)
//
//            hashSymbol.snp.makeConstraints { (maker) in
//                maker.top.bottom.equalToSuperview()
//                maker.left.equalToSuperview().offset(10)
//            }
//
//            nameLabel.snp.makeConstraints { (maker) in
//                maker.left.equalTo(hashSymbol.snp.right).offset(5)
//                maker.top.bottom.equalToSuperview()
//            }
//
//            icon.snp.makeConstraints { (maker) in
//                maker.left.equalTo(nameLabel.snp.right).offset(5)
//                maker.right.equalToSuperview().inset(10)
//                maker.width.height.equalTo(20)
//                maker.centerY.equalToSuperview()
//            }
//
//            return v
//        }()
        
//        private lazy var closeBtn: UIButton = {
//            let btn = UIButton(type: .custom)
//            btn.setImage(R.image.icon_close(), for: .normal)
//            btn.addTarget(self, action: #selector(onCloseBtn), for: .primaryActionTriggered)
//            return btn
//        }()
//        private var infoView: Among
        
        private lazy var userCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
//            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - itemSpacing * 4) / 5
            let cellWidth: CGFloat = 60
            var hInset: CGFloat = (UIScreen.main.bounds.width - cellWidth * 5) / 2
            let itemSpacing: CGFloat
            if hInset > 40 {
                itemSpacing = (hInset - 40) * 2 / 4
                hInset = 40
            } else {
                itemSpacing = 0
            }
            layout.itemSize = CGSize(width: cellWidth, height: 125.5)
            layout.minimumInteritemSpacing = itemSpacing
            layout.minimumLineSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 0, left: hInset, bottom: 0, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(UserCell.self, forCellWithReuseIdentifier: NSStringFromClass(UserCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.isScrollEnabled = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = nil
            return v
        }()
        
        private lazy var messageListTableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(AmongChat.Room.MessageTextCell.self, forCellReuseIdentifier: NSStringFromClass(AmongChat.Room.MessageTextCell.self))
            tb.backgroundColor = .clear
            tb.dataSource = self
            tb.delegate = self
            tb.isHidden = true
            tb.separatorStyle = .none
            tb.rowHeight = UITableView.automaticDimension
            tb.estimatedRowHeight = 80
            return tb
        }()
        
//        private lazy var messageBtn: UIButton = {
//            let btn = UIButton(type: .custom)
//            btn.addTarget(self, action: #selector(onMessageBtn), for: .primaryActionTriggered)
//            btn.backgroundColor = UIColor.white.alpha(0.8)
//            btn.layer.cornerRadius = 25
//            let image = R.image.btn_room_message()?.withRenderingMode(.alwaysTemplate)
//            btn.setImage(image, for: .normal)
//            btn.tintColor = UIColor(red: 38, green: 38, blue: 38)
//            btn.isHidden = true
//            return btn
//        }()
        
//        private lazy var micSwitchBtn: UIButton = {
//            let btn = UIButton(type: .custom)
//            btn.addTarget(self, action: #selector(onMicSwitchBtn(_:)), for: .primaryActionTriggered)
//            btn.backgroundColor = UIColor.white.alpha(0.8)
//            btn.layer.cornerRadius = 25
//            btn.setImage(R.image.icon_mic(), for: .normal)
//            btn.setImage(R.image.icon_mic_disable(), for: .selected)
//            return btn
//        }()
        
//        private lazy var shareBtn: UIButton = {
//            let btn = UIButton(type: .custom)
//            btn.addTarget(self, action: #selector(onShareBtn), for: .primaryActionTriggered)
//            btn.backgroundColor = UIColor.white.alpha(0.8)
//            btn.layer.cornerRadius = 25
//            let image = R.image.btn_room_share()?.withRenderingMode(.alwaysTemplate)
//            btn.setImage(image, for: .normal)
//            btn.tintColor = UIColor(red: 38, green: 38, blue: 38)
//            return btn
//        }()
        
//        private lazy var moreBtn: UIButton = {
//            let btn = UIButton(type: .custom)
//            btn.addTarget(self, action: #selector(onMoreBtn), for: .primaryActionTriggered)
//            btn.backgroundColor = UIColor.white.alpha(0.8)
//            btn.layer.cornerRadius = 25
//            btn.setImage(R.image.btn_more_action(), for: .normal)
//            return btn
//        }()
        
//        private lazy var bottomBtnStack: UIStackView = {
//            let s = UIStackView(arrangedSubviews: [micSwitchBtn, shareBtn, moreBtn],
//                                axis: .horizontal,
//                                spacing: 12,
//                                alignment: .fill,
//                                distribution: .fillEqually)
//
//            micSwitchBtn.snp.makeConstraints { (maker) in
//                maker.height.width.equalTo(50)
//            }
//
//            shareBtn.snp.makeConstraints { (maker) in
//                maker.height.width.equalTo(50)
//            }
//
//            moreBtn.snp.makeConstraints { (maker) in
//                maker.height.width.equalTo(50)
//            }
//
//            return s
//        }()
        
        private lazy var adContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            return v
        }()
        
//        private lazy var adView: MPAdView? = {
//            let adView = MPAdView(adUnitId: "2d4ccd8d270a4f8aa9afda3713ccdc8a")
//            adView?.delegate = self
//            adView?.frame = CGRect(origin: .zero, size: kMPPresetMaxAdSizeMatchFrame)
//            return adView
//        }()
        
        private lazy var messageInputContainerView: UIView = {
            let v = UIView()
            v.isHidden = true
            v.backgroundColor = .clear
            v.addSubview(messageInputField)
            messageInputField.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.height.equalTo(50)
            }
            return v
        }()
        
        private lazy var messageInputField: UITextField = {
            let f = UITextField(frame: CGRect.zero)
            f.backgroundColor = UIColor("#151515")
            f.borderStyle = .none
            let leftMargin = UIView()
            leftMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            let rightMargin = UIView()
            rightMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            f.leftView = leftMargin
            f.rightView = rightMargin
            f.leftViewMode = .always
            f.rightViewMode = .always
            f.returnKeyType = .send
            f.attributedPlaceholder = NSAttributedString(string: R.string.localizable.amongChatRoomMessagePlaceholder(),
                                                         attributes: [
                                                            NSAttributedString.Key.foregroundColor : UIColor("#8A8A8A")
                                                         ])
            f.textColor = .white
            f.delegate = self
            f.font = R.font.nunitoRegular(size: 13)
            return f
        }()
        
        static func join(room: Entity.Room, from controller: UIViewController) {
            controller.checkMicroPermission { [weak controller] in
                guard let controller = controller else {
                    return
                }
                let removeBlock = controller.view.raft.show(.loading, userInteractionEnabled: false)
                //show loading
    //            let hudRemoval = {
    //                removeBlock()
    //                self.view.isUserInteractionEnabled = true
    //            }
                let viewModel = ViewModel.make(room)
                viewModel.join { [weak controller] error in
                    removeBlock()
                    if let vc = controller, error == nil {
                        self.show(from: vc, with: room)
                    }
                }
            }
        }
        
        static func show(from controller: UIViewController, with room: Entity.Room) {
            let vc = AmongChat.Room.ViewController(room: room)
            vc.modalPresentationStyle = .fullScreen
            let transition = CATransition()
            transition.duration = 0.25
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromRight
            transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
            UIApplication.shared.keyWindow?.layer.add(transition, forKey: kCATransition)
            controller.present(vc, animated: false) { [weak controller] in
                controller?.navigationController?.popToRootViewController(animated: false)
            }
        }
                
        init(room: Entity.Room) {
            self.room = room
            self.viewModel = ViewModel(room: room)
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            bindSubviewEvent()
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            view.endEditing(true)
        }
        
    }
    
}

extension AmongChat.Room.ViewController {
    
    //MARK: - UI Action
    
    @objc
    private func onCopyNameBtn() {
//        channel.code.copyToPasteboard()
//        view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false)
    }
    
    @objc
    private func onCloseBtn() {
        
        let alertVC = UIAlertController(
            title: R.string.localizable.amongChatLeaveRoomTipTitle(),
            message: nil,
            preferredStyle: .alert
        )
        
        let confirm = UIAlertAction(title: R.string.localizable.toastConfirm(), style: .destructive, handler: { [weak self] _ in
            guard let `self` = self else { return }
            
            ChatRoomManager.shared.leaveChannel { (_) in
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = CATransitionType.push
                transition.subtype = CATransitionSubtype.fromLeft
                transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
                UIApplication.shared.keyWindow?.layer.add(transition, forKey: kCATransition)
                self.dismiss(animated: false) {
                    guard let vc = UIApplication.navigationController?.viewControllers.first as? AmongChat.Home.ViewController else { return }
                    Ad.InterstitialManager.shared.showAdIfReady(from: vc)
                }
            }
        })
        
        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        alertVC.addAction(confirm)
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc
    private func onShareBtn() {
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

extension AmongChat.Room.ViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fixedListLength
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UserCell.self), for: indexPath)
        if let cell = cell as? UserCell {
            cell.bind(dataSource[indexPath.item], topic: room.topicId)
        }
        return cell
    }
    
}

extension AmongChat.Room.ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = dataSource[indexPath.item] else {
            //show
            self.onShareBtn()
            return
        }
        //enter profile page
    }
    
}

//extension AmongChat.Room.ViewController: MPAdViewDelegate {
//
//    //MARK: - MPAdViewDelegate
//
//    func viewControllerForPresentingModalView() -> UIViewController! {
//        if let naviVC = self.navigationController {
//            return naviVC
//        } else {
//            return self
//        }
//    }
//
//    func adViewDidLoadAd(_ view: MPAdView!, adSize: CGSize) {
//        Logger.Ads.logEvent(.ads_loaded, .channel)
//    }
//
//    func adView(_ view: MPAdView!, didFailToLoadAdWithError error: Error!) {
//        Logger.Ads.logEvent(.ads_failed, .channel)
//    }
//
//    func willPresentModalView(forAd view: MPAdView!) {
//        Logger.Ads.logEvent(.ads_imp, .channel)
//    }
//
//    func willLeaveApplication(fromAd view: MPAdView!) {
//        Logger.Ads.logEvent(.ads_clk, .channel)
//    }
//
//    func didDismissModalView(forAd view: MPAdView!) {
//    }
//
//}


extension AmongChat.Room.ViewController {
    
    // MARK: -
    
    private func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hex6: 0x00011B)
        
        topBar = AmongChatRoomTopBar()
        configView = AmongChatRoomConfigView(room)
        
        amongInputCodeView = AmongInputCodeView()
        amongInputCodeView.alpha = 0
        
        bottomBar = AmongRoomBottomBar()
        bottomBar.isMicOn = true
        
        toolView = AmongRoomToolView()
        
        nickNameInputView = AmongInputNickNameView()
        nickNameInputView.alpha = 0
        
        inputNotesView = AmongInputNotesView()
        inputNotesView.alpha = 0
        
        view.addSubviews(views: bgView, userCollectionView, messageListTableView, messageInputContainerView, amongInputCodeView, topBar, configView, toolView, bottomBar, nickNameInputView, inputNotesView)
        
        topBar.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(60)
        }
        
        configView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topBar.snp.bottom)
            maker.height.equalTo(107)
        }
        
        bgView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
//        copyNameBtn.snp.makeConstraints { (maker) in
//            maker.left.equalToSuperview().inset(17)
//            maker.centerY.equalTo(closeBtn)
//            maker.height.equalTo(30)
//        }
//
//        closeBtn.snp.makeConstraints { (maker) in
//            maker.height.width.equalTo(44)
//            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(2)
//            maker.right.equalTo(-6)
//        }
        
        userCollectionView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(configView.snp.bottom).offset(40)
            maker.height.equalTo(251)
        }
        
        toolView.snp.makeConstraints { (maker) in
            maker.top.equalTo(userCollectionView.snp.bottom)
            maker.height.equalTo(24)
            maker.left.right.equalToSuperview()
        }
        
        messageListTableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(toolView.snp.bottom).offset(17)
            maker.bottom.equalTo(bottomBar.snp.top).offset(-10)
            maker.left.right.equalToSuperview()
        }
        
//        messageBtn.snp.makeConstraints { (maker) in
//            maker.height.width.equalTo(50)
//            maker.centerY.equalTo(bottomBtnStack)
//            maker.left.equalToSuperview().inset(16)
//        }
//
//        bottomBtnStack.snp.makeConstraints { (maker) in
//            maker.trailing.equalTo(-16)
//            maker.bottom.equalTo(adContainer.snp.top).offset(-12)
//            maker.height.equalTo(50)
//        }
//
//        adContainer.snp.makeConstraints { (maker) in
//            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
//            maker.centerX.equalToSuperview()
//            maker.height.equalTo(50)
//        }
        
        messageInputContainerView.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        amongInputCodeView.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        nickNameInputView.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        inputNotesView.snp.makeConstraints { (maker) in
            maker.left.top.right.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        bottomBar.snp.makeConstraints { maker in
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-5)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(42)
        }
        
//        if channel.name.isPrivate {
//            showShareController(channelName: channel.name)
//        }
        
//        if let adView = self.adView {
//            adContainer.addSubview(adView)
//            adView.snp.makeConstraints { (maker) in
//                maker.size.equalTo(CGSize(width: 320, height: 50))
//                maker.edges.equalToSuperview()
//            }
//        }

    }
    
    private func showShareController(channelName: String) {
        let controller = R.storyboard.main.privateShareController()
        controller?.channelName = channelName
        controller?.showModal(in: self)
    }
    
    private func showMoreSheet(for userViewModel: ChannelUserViewModel) {
        let alertVC = UIAlertController(
            title: nil,
            message: R.string.localizable.userListMoreSheet(),
            preferredStyle: .actionSheet
        )
        
//        if let firestoreUser = userViewModel.firestoreUser {
//            let followingUids = Social.Module.shared.followingValue.map { $0.uid }
//            if !followingUids.contains(firestoreUser.uid) {
//                //未添加到following
//                let followAction = UIAlertAction(title: R.string.localizable.channelUserListFollow(), style: .default) { [weak self] (_) in
//                    // follow_clk log
//                    GuruAnalytics.log(event: "follow_clk", category: nil, name: nil, value: nil, content: nil)
//                    //
//                    self?.viewModel.followUser(firestoreUser)
//                }
//                alertVC.addAction(followAction)
//            } else {
//                let unfollowAction = UIAlertAction(title: R.string.localizable.socialUnfollow(), style: .destructive) { [weak self] (_) in
//                    // unfollow_clk log
//                    GuruAnalytics.log(event: "unfollow_clk", category: nil, name: nil, value: nil, content: nil)
//                    //
//                    self?.viewModel.unfollowUser(firestoreUser)
//                }
//                alertVC.addAction(unfollowAction)
//            }
//        }
        
        let isMuted = Social.Module.shared.mutedValue.contains(userViewModel.channelUser.uid.uIntValue)
        if isMuted {
            let unmuteAction = UIAlertAction(title: R.string.localizable.channelUserListUnmute(), style: .default) { [weak self] (_) in
                // unmute_clk log
                GuruAnalytics.log(event: "unmute_clk", category: nil, name: nil, value: nil, content: nil)
                //
                self?.viewModel.unmuteUser(userViewModel)
                ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 100)
            }
            alertVC.addAction(unmuteAction)
            
        } else {
            let muteAction = UIAlertAction(title: R.string.localizable.channelUserListMute(), style: .default) { [weak self] (_) in
                
                // mute_clk log
                GuruAnalytics.log(event: "mute_clk", category: nil, name: nil, value: nil, content: nil)
                //
                
                let modal = ActionModal(with: userViewModel, actionType: .mute)
                modal.actionHandler = { () in
                    self?.viewModel.muteUser(userViewModel)
                    ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 0)
                }
                modal.showModal(in: self)
            }
            alertVC.addAction(muteAction)
        }
        
        let reportAction = UIAlertAction(title: R.string.localizable.reportTitle(), style: .default, handler: { [weak self] _ in
            self?.showReportSheet(for: userViewModel)
        })
        let blockAction = UIAlertAction(title:userViewModel.channelUser.status == .blocked ? R.string.localizable.alertUnblock() : R.string.localizable.alertBlock(), style: .default, handler: { [weak self] _ in
            // block_clk log
            GuruAnalytics.log(event: "block_clk", category: "user_list", name: nil, value: nil, content: nil)
            //
            self?.showBlockAlert(with: userViewModel)
        })
        alertVC.addAction(reportAction)
        alertVC.addAction(blockAction)
        
        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showReportSheet(for userViewModel: ChannelUserViewModel) {
        let user = userViewModel.channelUser
        let alertVC = UIAlertController(
            title: R.string.localizable.reportTitle(),
            message: "\(R.string.localizable.reportUserId()): \(user.uid)",
            preferredStyle: .actionSheet)

        let items = [
            R.string.localizable.reportIncorrectInformation(),
            R.string.localizable.reportIncorrectSexual(),
            R.string.localizable.reportIncorrectHarassment(),
            R.string.localizable.reportIncorrectUnreasonable(),
            ].enumerated()

        for (index, item) in items {
            let action = UIAlertAction(title: item, style: .default, handler: { [weak self] _ in
                self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
                Logger.Report.logImp(itemIndex: index, channelName: String(user.uid))
            })
            alertVC.addAction(action)
        }

        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showBlockAlert(with userViewModel: ChannelUserViewModel) {
        guard userViewModel.channelUser.status != .blocked else {
            viewModel.unblockedUser(userViewModel)
            ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 100)
            return
        }
        let modal = ActionModal(with: userViewModel, actionType: .block)
        modal.actionHandler = { [weak self] in
            self?.viewModel.blockedUser(userViewModel)
            ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 0)
        }
        modal.showModal(in: self)
    }
    
    private func bindSubviewEvent() {
        
//        AdsManager.shared.mopubInitializeSuccessSubject
//            .filter { _ -> Bool in
//                return !Settings.shared.isProValue.value
//            }
//            .filter { $0 }
//            .observeOn(MainScheduler.asyncInstance)
//            .subscribe(onNext: { [weak self] _ in
//                self?.loadAdView()
//            })
//            .disposed(by: bag)
        
//        Settings.shared.isProValue.replay()
//            .observeOn(MainScheduler.asyncInstance)
//            .subscribe(onNext: { [weak self] (isPro) in
//                guard let `self` = self else { return }
//
//                if isPro {
//                    //remove ad
//                    self.adView?.stopAutomaticallyRefreshingContents()
//                } else {
//                    self.adView?.loadAd()
//                }
//
//                self.adContainer.snp.updateConstraints { (maker) in
//                    maker.height.equalTo(isPro ? 0 : 50)
//                }
//                self.adView?.isHidden = isPro
//            })
//            .disposed(by: bag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                switch self.editType {
                case .amongSetup:
                    self.amongInputCodeView.snp.updateConstraints { (maker) in
                        maker.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-keyboardVisibleHeight)
                    }
                case .nickName:
                    self.nickNameInputView.snp.updateConstraints { (maker) in
                        maker.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-keyboardVisibleHeight)
                    }
                case .chillingSetup:
                    self.inputNotesView.snp.updateConstraints { (maker) in
                        maker.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-keyboardVisibleHeight)
                    }
                default:
                    self.messageInputContainerView.snp.updateConstraints { (maker) in
                        maker.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-keyboardVisibleHeight)
                    }
                }
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: bag)
        
//        viewModel.userObservable
//            .subscribe(onNext: { [weak self] (channelUsers) in
////                self?.dataSource = channelUsers
//            })
//            .disposed(by: bag)
        
//        imViewModel.messagesObservable
//            .subscribe(onNext: { [weak self] (msgs) in
//                self?.messageListDataSource = msgs
//            })
//            .disposed(by: bag)
//        
//        imViewModel.imReadySignal
//            .filter({ $0 })
//            .take(1)
//            .subscribe(onNext: { [weak self] (_) in
//                self?.messageListTableView.isHidden = false
////                self?.messageBtn.isHidden = false
//            })
//            .disposed(by: bag)
        
        viewModel.roomReplay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] room in
                self?.room = room
                self?.topBar.set(room)
                self?.configView.room = room
                self?.toolView.set(room)
                self?.dataSource = room.userListMap
                    
                //update list and other
//                self?.userCollectionView.reloadData()
            })
            .disposed(by: bag)

        
        configView.updateEditTypeHandler = { [weak self] editType in
            self?.editType = editType
        }
        
        topBar.leaveHandler = { [weak self] in
            self?.onCloseBtn()
        }
        
        topBar.kickOffHandler = { [weak self] in
            
        }
        
        topBar.reportHandler = { [weak self] in
            self?.showReportRoomSheet()
        }
        topBar.changePublicStateHandler = { [weak self] in
            self?.viewModel.changePublicType()
        }
        
        bottomBar.sendMessageHandler = { [weak self] in
            self?.editType = .message
        }
        
        bottomBar.shareHandler = { [weak self] in
//            self?.editType = .message
            self?.onShareBtn()
        }
        
        bottomBar.changeMicStateHandler = { [weak self] micOn in
//            self?.editType = .message
            ChatRoomManager.shared.muteMyMic(muted: !micOn)
            let tip = micOn ? R.string.localizable.amongChatRoomTipMicOff() : R.string.localizable.amongChatRoomTipMicOn()
            self?.view.raft.autoShow(.text(tip), userInteractionEnabled: false)
        }
        
        amongInputCodeView.inputResultHandler = { [weak self] code, aera in
            self?.viewModel.updateAmong(code: code, aera: aera)
        }
        
        nickNameInputView.inputResultHandler = { [weak self] text in
            self?.viewModel.update(nickName: text)
        }
        
        inputNotesView.inputResultHandler = { [weak self] notes in
            self?.viewModel.update(notes: notes)
        }
        
        toolView.setNickNameHandler = { [weak self] in
            self?.editType = .nickName
        }
        
        toolView.openGameHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            switch self.room.topicId {
            case .amongus:
                self.showStoreProduct(with: 1351168404)
            case .roblox:
                self.showStoreProduct(with: 431946152)
            case .chilling:
                ()
            }
        }
    }
    
    private func loadAdView() {
//        adView?.loadAd(withMaxAdSize: kMPPresetMaxAdSizeMatchFrame)
//        Logger.Ads.logEvent(.ads_load, .channel)
//        adView?.startAutomaticallyRefreshingContents()
    }
    
}

extension AmongChat.Room.ViewController {
    
    private func showMoreSheet(for channel: Entity.Room) {
        let alertVC = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let reportAction = UIAlertAction(title: R.string.localizable.reportTitle(), style: .default, handler: { [weak self] _ in
            guard let `self` = self else { return }
//            self.showReportSheet(for: channel)
        })
        alertVC.addAction(reportAction)
        
        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showReportRoomSheet() {
        let alertVC = UIAlertController(
            title: R.string.localizable.reportTitle(),
            message: "\(R.string.localizable.reportRoomId()): \(room.roomId)",
            preferredStyle: .actionSheet)

        let items = [
            R.string.localizable.reportIncorrectInformation(),
            R.string.localizable.reportIncorrectSexual(),
            R.string.localizable.reportIncorrectHarassment(),
            R.string.localizable.reportIncorrectUnreasonable(),
            ].enumerated()

        for (index, item) in items {
            let action = UIAlertAction(title: item, style: .default, handler: { [weak self] _ in
                guard let `self` = self else { return }
                self.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
                Logger.Report.logImp(itemIndex: index, channelName: self.room.roomId)
            })
            alertVC.addAction(action)
        }

        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
}

extension AmongChat.Room.ViewController: UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        messageInputContainerView.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        messageInputContainerView.isHidden = false
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 256
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        guard let text = textField.text,
              text.count > 0 else {
            return true
        }
        
        textField.clear()
        //text
        viewModel.sendText(message: text)
        return true
    }
}

extension AmongChat.Room.ViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(AmongChat.Room.MessageTextCell.self), for: indexPath)
        
        if let cell = cell as? AmongChat.Room.MessageTextCell,
           let model = viewModel.messages.safe(indexPath.row) {
            cell.configCell(with: model)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let model = viewModel.messages.safe(indexPath.row) {
//            model.text.copyToPasteboard()
//            view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false)
        }
        
    }
    
}
