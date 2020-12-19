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
////import MoPub

extension AmongChat.Room {
    enum EditType {
        case message
        case amongSetup
        case robloxSetup
        case nickName
        case chillingSetup
    }
    
    //样式
    enum Style {
        case normal
        case kick
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
        
        private var style = Style.normal {
            didSet {
                UIView.animate(withDuration: 0.2) { [unowned self] in
                    topBar.alpha = style == .normal ? 1 : 0
                    toolView.alpha = style == .normal ? 1 : 0
                    messageView.alpha = style == .normal ? 1 : 0
                }
                seatView.style = style
                bottomBar.style = style
            }
        }
        
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
                    inputNotesView.notes = room.note
                    inputNotesView.show(with: room)
                default:
                    messageInputField.becomeFirstResponder()
                }
            }
        }

        private lazy var bgView: UIView = {
            let v = UIView()
            let ship = UIImageView(image: R.image.space_ship_bg())
            ship.contentMode = .scaleAspectFill
            if room.bgUrl != nil {
                ship.setImage(with: room.bgUrl)
            }
//            let star = UIImageView(image: R.image.star_bg())
            let mask = UIView()
            mask.backgroundColor = UIColor.black.alpha(0.5)
            v.addSubviews(views: ship, mask)
//            star.snp.makeConstraints { (maker) in
//                maker.edges.equalToSuperview()
//            }
            ship.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            mask.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }()
        
        private lazy var seatView: AmongChat.Room.SeatView = {
            let view = AmongChat.Room.SeatView(room: room, viewModel: viewModel)
//            view.room = room
            return view
        }()
        
        private lazy var messageView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(AmongChat.Room.MessageTextCell.self, forCellReuseIdentifier: NSStringFromClass(AmongChat.Room.MessageTextCell.self))
            tb.backgroundColor = .clear
            tb.dataSource = self
            tb.delegate = self
//            tb.isHidden = true
            tb.separatorStyle = .none
            tb.rowHeight = UITableView.automaticDimension
            tb.estimatedRowHeight = 80
            
            return tb
        }()
        
        private lazy var messageBackgroundLayer = CAGradientLayer()
        private lazy var messageBackgroundView: UIView = {
           let view = UIView()
            view.layer.insertSublayer(messageBackgroundLayer, at: 0)
            return view
        }()
        
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
        
        static func join(room: Entity.Room, from controller: UIViewController, completionHandler: ((Error?) -> Void)? = nil) {
            controller.checkMicroPermission { [weak controller] in
                guard let controller = controller else {
                    return
                }
                let removeBlock: CallBack?
                if completionHandler == nil {
                    removeBlock = controller.view.raft.show(.loading, userInteractionEnabled: false)
                } else {
                    removeBlock = nil
                }
                //show loading
                let viewModel = ViewModel.make(room)
                viewModel.join { [weak controller] error in
                    removeBlock?()
                    completionHandler?(error)
                    if let vc = controller, error == nil {
                        self.show(from: vc, with: viewModel)
                    }
                }
            }
        }
        
        static func show(from controller: UIViewController, with viewModel: ViewModel) {
            let vc = AmongChat.Room.ViewController(viewModel: viewModel)
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
                
        init(viewModel: ViewModel) {
            self.room = viewModel.roomReplay.value
            self.viewModel = viewModel
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
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            messageBackgroundLayer.frame = messageBackgroundView.bounds
        }
    }
    
}

extension AmongChat.Room.ViewController {
    
    //MARK: - UI Action
    
    @objc
    private func onCloseBtn() {
  
        showAmongAlert(title: R.string.localizable.amongChatLeaveRoomTipTitle(), message: nil, cancelTitle: R.string.localizable.toastCancel()) { [weak self] in
            guard let `self` = self else { return }
            self.requestLeaveRoom()
        }
//        let alertVC = UIAlertController(
//            title: R.string.localizable.amongChatLeaveRoomTipTitle(),
//            message: nil,
//            preferredStyle: .alert
//        )
//        alertVC.setBackgroundColor(color: "222222".color())
//        alertVC.setTitlet(font: R.font.nunitoExtraBold(size: 17), color: .white)
//        alertVC.setMessage(font: R.font.nunitoExtraBold(size: 13), color: .white)
//
//        let confirm = UIAlertAction(title: R.string.localizable.toastConfirm(), style: .destructive, handler: { [weak self] _ in
//            guard let `self` = self else { return }
//            self.requestLeaveRoom()
//        })
//        confirm.titleTextColor = .white
//        let cancel = UIAlertAction(title: R.string.localizable.toastCancel(), style: .default)
//        cancel.titleTextColor = .white
////        cancel.setTitlet(font: R.font.nunitoExtraBold(size: 15), color: .white)
//
//        alertVC.addAction(cancel)
//        alertVC.addAction(confirm)
//        present(alertVC, animated: true, completion: nil)
    }
    
    @objc
    private func onShareBtn() {
//        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
//        let removeBlock = { [weak self] in
//            self?.view.isUserInteractionEnabled = true
//            removeHUDBlock()
//        }
//
//        self.view.isUserInteractionEnabled = false

        ShareManager.default.showActivity(name: nil, dynamicLink: "https://among.chat/room/\(room.roomId)", type: .more, viewController: self) { () in
//            removeBlock()
        }
    }
    
    func requestLeaveRoom(completionHandler: CallBack? = nil) {
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        self.viewModel.leaveChannel()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe { [weak self] _ in
                removeBlock()
                self?.dismissViewController(completionHandler: {
                    completionHandler?()
                })
            } onError: { [weak self] error in
                removeBlock()
                self?.dismissViewController(completionHandler: {
                    completionHandler?()
                })
            }
            .disposed(by: bag)
    }
    
    func dismissViewController(completionHandler: CallBack? = nil) {
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
        UIApplication.shared.keyWindow?.layer.add(transition, forKey: kCATransition)
        self.dismiss(animated: false) {
            completionHandler?()
            
            //Ad.InterstitialManager.shared.showAdIfReady(from: vc)
        }
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
        
        messageBackgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        messageBackgroundLayer.endPoint = CGPoint(x: 0, y: 1)
        messageBackgroundLayer.colors = [UIColor.black.alpha(0).cgColor, UIColor.black.alpha(0.6).cgColor]
        
        view.addSubviews(views: bgView, messageBackgroundView, messageView, seatView, messageInputContainerView, amongInputCodeView, topBar, configView, toolView, bottomBar, nickNameInputView, inputNotesView)
        
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

        let seatViewTopEdge = Frame.Height.deviceDiagonalIsMinThan4_7 ? 0 : 40
        seatView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(configView.snp.bottom).offset(seatViewTopEdge)
            maker.height.equalTo(251)
        }
        
        toolView.snp.makeConstraints { (maker) in
            maker.top.equalTo(seatView.snp.bottom)
            maker.height.equalTo(24)
            maker.left.right.equalToSuperview()
        }
        let messageViewTopEdge = Frame.Height.deviceDiagonalIsMinThan4_7 ? 0 : 17
        messageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(toolView.snp.bottom).offset(messageViewTopEdge)
            maker.bottom.equalTo(bottomBar.snp.top).offset(-10)
            maker.left.right.equalToSuperview()
        }
        
        messageBackgroundView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalTo(messageView)
            maker.bottom.equalToSuperview()
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
            maker.bottom.equalToSuperview()
        }
        
        amongInputCodeView.snp.makeConstraints { (maker) in
            maker.left.top.right.bottom.equalToSuperview()
        }
        
        nickNameInputView.snp.makeConstraints { (maker) in
            maker.left.top.right.bottom.equalToSuperview()
        }
        
        inputNotesView.snp.makeConstraints { (maker) in
            maker.left.top.right.bottom.equalToSuperview()
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
    
    private func showReportSheet(for user: Entity.RoomUser) {
        let alertVC = UIAlertController(
            title: R.string.localizable.reportTitle(),
            message: "\(R.string.localizable.reportUserId()): \(user.uid)",
            preferredStyle: .actionSheet)
//        alertVC.setBackgroundColor(color: "222222".color())
//        alertVC.setTitlet(font: R.font.nunitoExtraBold(size: 17), color: .white)
//        alertVC.setMessage(font: R.font.nunitoExtraBold(size: 13), color: .white)

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
//            action.titleTextColor = .white
            
            alertVC.addAction(action)
        }

        let cancel = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel)
//        cancel.titleTextColor = .white
        alertVC.addAction(cancel)
        present(alertVC, animated: true, completion: nil)
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
                        maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    }
                case .nickName:
                    self.nickNameInputView.snp.updateConstraints { (maker) in
                        maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    }
                case .chillingSetup:
                    self.inputNotesView.snp.updateConstraints { (maker) in
                        maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    }
                default:
                    self.messageInputContainerView.snp.updateConstraints { (maker) in
                        maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    }
                }
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: bag)

//        imViewModel.imReadySignal
//            .filter({ $0 })
//            .take(1)
//            .subscribe(onNext: { [weak self] (_) in
//                self?.messageView.isHidden = false
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
                self?.seatView.room = room
                    
                //update list and other
//                self?.userCollectionView.reloadData()
            })
            .disposed(by: bag)
        
        viewModel.soundAnimationIndex
            .bind(to: seatView.rx.soundAnimation)
            .disposed(by: bag)

        viewModel.messageEventHandler = { [weak self] in
            guard let `self` = self else { return }
            let contentHeight = self.messageView.contentSize.height
            let height = self.messageView.bounds.size.height
            let contentOffsetY = self.messageView.contentOffset.y
            let bottomOffset = contentHeight - contentOffsetY
//            self.newMessageButton.isHidden = true
            // 消息不足一屏
            if contentHeight < height {
                self.messageView.reloadData()
            } else {// 超过一屏
                if floor(bottomOffset) - floor(height) < 40 {// 已经在底部
                    let rows = self.messageView.numberOfRows(inSection: 0)
                    let newRow = self.viewModel.messages.count
                    guard newRow > rows else { return }
                    let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                    self.messageView.beginUpdates()
                    self.messageView.insertRows(at: indexPaths, with: .none)
                    self.messageView.endUpdates()
                    if let endPath = indexPaths.last {
                        self.messageView.scrollToRow(at: endPath, at: .bottom, animated: true)
                    }
                } else {
//                    if self.messageView.numberOfRows(inSection: 0) <= 2 {
//                        self.newMessageButton.isHidden = true
//                    } else {
//                        self.newMessageButton.isHidden = false
//                    }
                    self.messageView.reloadData()
                }
            }
        }
        
        viewModel.endRoomHandler = { [weak self] action in
            guard let `self` = self else { return }
            if action == .kickout {
                self.requestLeaveRoom {
                    let vc = UIApplication.navigationController?.viewControllers.first
                    vc?.showKickedAlert()
                }
            }
//            guard action != .normalClose else {
//                self.closeRoom()
//                return
//            }
//            guard action != .enterClosedRoom else {
//                self.closeRoom(isEnterClosedRoom: true)
//                return
//            }
//            let title: String
//            let confirmEventBlock = { [weak self] in
//                self?.leaveRoom()
//            }
//            switch action {
//            case .accountKicked:
//                title = NSLocalizedString("listener.multidevice.tip", comment: "")
//            case .disconnected:
//                title = R.string.localizable.listenerDisconnectedTip()
//            case .tokenError:
//                title = NSLocalizedString("Token error", comment: "")
//            case .kickout:
//                title = R.string.localizable.listenerEnterBeenKickout()
//            case .beBlocked:
//                title = NSLocalizedString("listener.blocked.tip", comment: "")
//            // 主播封禁
//            case .forbidden:
//                title = NSLocalizedString("broadcaster.forbid.tip", comment: "")
//            default:
//                title = ""
//            }
//            guard !title.isEmpty else {
//                return
//            }
//
//            var currentVC: UIViewController? = self
//            if (action == .accountKicked || action == .disconnected), let viewController = UIApplication.shared.keyWindow?.topViewController() {
//                //ps: 处理转盘弹起的状态下，账号被顶掉
//                currentVC = viewController
//            }
//            let alertVC = UIAlertController(title: title, message: nil, preferredStyle: .alert)
//
//            let cancelAction = UIAlertAction(title: R.string.localizable.oK(), style: .cancel) { _ in
//                if !(currentVC is Listener.ViewController) {
//                    currentVC?.dismiss(animated: true, completion: nil)
//                }
//                confirmEventBlock()
//            }
//            alertVC.addAction(cancelAction)
//            currentVC?.present(alertVC, animated: true, completion: nil)
//            if action == .kickout || action == .beBlocked {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
//                    alertVC.dismiss(animated: true, completion: nil)
//                    self?.leaveRoom()
//                }
//            }
        }
        
        configView.updateEditTypeHandler = { [weak self] editType in
            self?.editType = editType
        }
        
        topBar.leaveHandler = { [weak self] in
            self?.onCloseBtn()
//            self?.viewModel.endRoomHandler?(.kickout)
        }
        
        topBar.kickOffHandler = { [weak self] in
            self?.style = .kick
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
            self?.viewModel.isMuteMic = !micOn
        }
        
        bottomBar.cancelKickHandler = { [weak self] in
            self?.style = .normal
        }
        
        bottomBar.kickSelectedHandler = { [weak self] users in
            guard let `self` = self else { return }
            self.requestKick(users)
        }
        
        seatView.selectedKickUserHandler = { [weak self] users in
            self?.bottomBar.selectedKickUser = users
        }
        
        seatView.userProfileSheetActionHandler = { [weak self] item, user in
            self?.onUserProfileSheet(action: item, user: user)
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
        
        seatView.selectUserHandler = { [weak self] user in
            guard let user = user else {
                self?.onShareBtn()
                return
            }
        }
    }
    
    func onUserProfileSheet(action: AmongSheetController.ItemType, user: Entity.RoomUser) {
        switch action {
        case .block:
            viewModel.blockedUser(user)
        case .mute:
            viewModel.muteUser(user)
        case .unblock:
            viewModel.unblockedUser(user)
        case .unmute:
            viewModel.unmuteUser(user)
        case .report:
            showReportSheet(for: user)
        case .kick:
            requestKick([user.uid])
        default:
            ()
        }
    }
    
    func requestKick(_ users: [Int]) {
        let removeBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
        self.viewModel.requestKick(users)
            .subscribe { [weak self] result in
                removeBlock()
                self?.style = .normal
            } onError: { error in
                removeBlock()
            }
            .disposed(by: self.bag)
    }
    
    private func loadAdView() {
//        adView?.loadAd(withMaxAdSize: kMPPresetMaxAdSizeMatchFrame)
//        Logger.Ads.logEvent(.ads_load, .channel)
//        adView?.startAutomaticallyRefreshingContents()
    }
    
    func messageListScrollToBottom() {
        let rows = self.messageView.numberOfRows(inSection: 0)
        if rows > 0 {
            let endPath = IndexPath(row: rows - 1, section: 0)
            self.messageView.scrollToRow(at: endPath, at: .bottom, animated: true)
        }
    }
}

extension AmongChat.Room.ViewController {
    
//    private func showMoreSheet(for channel: Entity.Room) {
//        let alertVC = UIAlertController(
//            title: nil,
//            message: nil,
//            preferredStyle: .actionSheet
//        )
////        alertVC.setBackgroundColor(color: "222222".color())
////        alertVC.setTitlet(font: R.font.nunitoExtraBold(size: 17), color: .white)
//        let reportAction = UIAlertAction(title: R.string.localizable.reportTitle(), style: .default, handler: { [weak self] _ in
//            guard let `self` = self else { return }
////            self.showReportSheet(for: channel)
//        })
////        reportAction.titleTextColor = .white
//        let cancel = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel)
////        cancel.titleTextColor = .white
//
//        alertVC.addAction(reportAction)
//        alertVC.addAction(cancel)
//        present(alertVC, animated: true, completion: nil)
//    }
    
    private func showReportRoomSheet() {
        let alertVC = UIAlertController(
            title: R.string.localizable.reportTitle(),
            message: "\(R.string.localizable.reportRoomId()): \(room.roomId)",
            preferredStyle: .actionSheet)
//        alertVC.setBackgroundColor(color: "222222".color())
//        alertVC.setTitlet(font: R.font.nunitoExtraBold(size: 17), color: .white)
//        alertVC.setMessage(font: R.font.nunitoExtraBold(size: 13), color: .white)

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
//            action.titleTextColor = .white
            alertVC.addAction(action)
        }
        let cancel = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel)
//        cancel.titleTextColor = .white
        alertVC.addAction(cancel)
        present(alertVC, animated: true, completion: nil)
    }
}

extension AmongChat.Room.ViewController: UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        messageInputContainerView.isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        view.bringSubviewToFront(messageInputContainerView)
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
