//
//  AmongChat.GroupRoom.ViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension AmongChat.GroupRoom {
    
    class ViewController: WalkieTalkie.ViewController, GestureBackable {
        
        var isEnableScreenEdgeGesture: Bool = false
        
        private typealias UserCell = AmongChat.Room.UserCell
        
        private var room: Entity.Room
        private let viewModel: ViewModel

        private var topBar: AmongGroupTopView!
//        private var configView: AmongChatRoomConfigView!
        private var amongInputCodeView: AmongInputCodeView!
        private var inputNotesView: AmongInputNotesView!
        private var nickNameInputView: AmongInputNickNameView!
        private var bottomBar: AmongRoomBottomBar!
//        private var toolView: AmongRoomToolView!
        private weak var socialShareViewController: Social.ShareRoomViewController?
        private var isKeyboardVisible = false
        private var keyboardHiddenBlock: CallBack?
        
        var switchLiveRoomHandler: ((Entity.Room) -> Void)?
        //显示父视图 loading
        var showContainerLoading: ((Bool) -> Void)?
        var showInnerJoinLoading: Bool = false
        
        private lazy var emojiPickerViewModel = AmongChat.Room.EmojiViewModel()
        
        private var style = AmongChat.Room.Style.normal {
            didSet {
                UIView.animate(withDuration: 0.1) { [unowned self] in
                    topBar.alpha = style == .normal ? 1 : 0
//                    toolView.alpha = style == .normal ? 1 : 0
                    messageView.alpha = style == .normal ? 1 : 0
//                    configView.alpha = style == .normal ? 1 : 0
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
                    amongInputCodeView.becomeFirstResponder(with: room)
                    Logger.Action.log(.admin_edit_imp, categoryValue: room.topicId)
                case .nickName:
                    self.view.bringSubviewToFront(nickNameInputView)
                    nickNameInputView.becomeFirstResponder(with: room)
                    Logger.Action.log(.room_edit_nickname, categoryValue: room.topicId)
                case .chillingSetup:
                    self.view.bringSubviewToFront(inputNotesView)
                    inputNotesView.notes = room.note
                    inputNotesView.show(with: room)
                    Logger.Action.log(.admin_edit_imp, categoryValue: room.topicId)
                default:
                    Logger.Action.log(.room_send_message_clk, categoryValue: self.room.topicId)
//                    messageInputField.becomeFirstResponder()
                    messageInputContainerView.becomeFirstResponder()
                }
            }
        }

        private lazy var bgView: UIView = {
            let v = UIView()
            let ship = UIImageView()
            ship.contentMode = .scaleAspectFill
            if let image = viewModel.roomBgImage() {
                ship.image = image
            } else {
                ship.setImage(with: viewModel.roomBgUrl())
            }
            let mask = UIView()
            mask.backgroundColor = UIColor.black.alpha(0.5)
            v.addSubviews(views: ship, mask)
            ship.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            mask.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }()
        
        lazy var hostView = AmongGroupHostView()
        private lazy var seatView: AmongChat.Room.SeatView = {
            return AmongChat.Room.SeatView(room: room, viewModel: viewModel)
        }()
        
        private lazy var messageView: AmongChat.Room.MessageListView = {
            let tb = AmongChat.Room.MessageListView()
            return tb
        }()
                
        private lazy var adContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var messageInputContainerView: AmongChat.Room.MessageInputView = {
            let v = AmongChat.Room.MessageInputView(sendable: viewModel)
            v.isHidden = true
            v.backgroundColor = .clear
            return v
        }()
        
        private var topEntranceView: AmongChat.Room.TopEntranceView!
        
        override var screenName: Logger.Screen.Node.Start {
            return .room
        }
        
        static func join(room: Entity.Room, from controller: UIViewController, logSource: ParentPageSource? = nil, completionHandler: ((Error?) -> Void)? = nil) {
            controller.checkMicroPermission { [weak controller] in
                guard let controller = controller else {
                    return
                }
                Logger.Action.log(.room_enter, categoryValue: room.topicId, logSource?.key)
                //show loading
                let viewModel = ViewModel(room: room, source: logSource)
                self.show(from: controller, with: viewModel)
                completionHandler?(nil)
            }
        }
        
        static func show(from controller: UIViewController, with viewModel: ViewModel) {
            let vc = AmongChat.Room.ViewController(viewModel: viewModel)
            controller.navigationController?.pushViewController(vc, completion: { [weak controller] in
                guard let ancient = controller,
                      (ancient is AmongChat.CreateRoom.ViewController || ancient is AmongChat.Room.ViewController) else { return }
                ancient.navigationController?.viewControllers.removeAll(ancient)
            })
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
    }
    
}

extension AmongChat.GroupRoom.ViewController {
    
    //MARK: - UI Action
    
    @objc
    private func onCloseBtn() {
        showAmongAlert(title: R.string.localizable.amongChatLeaveRoomTipTitle(), message: nil, cancelTitle: R.string.localizable.toastCancel()) { [weak self] in
            guard let `self` = self else { return }
            self.requestLeaveRoom { [weak self] in
                self?.showRecommendUser()
            }
        }
    }
    
    @objc
    private func onShareBtn() {
        guard !isKeyboardVisible else {
            keyboardHiddenBlock = { [weak self] in
                self?.onShareBtn()
            }
            return
        }
        guard socialShareViewController == nil else {
            return
        }
        let link = "https://among.chat/room/\(room.roomId)"
        let vc = Social.ShareRoomViewController(with: link, roomId: room.roomId, topicId: viewModel.roomReplay.value.topicId)
        vc.showModal(in: self)

        viewModel.didShowShareView()
        socialShareViewController = vc
    }
    
    func requestLeaveRoom(completionHandler: CallBack? = nil) {
        Logger.Action.log(.room_leave_clk, categoryValue: room.topicId, nil, viewModel.stayDuration)
        
        viewModel.requestLeaveChannel()
            .subscribe { _ in
                cdPrint("requestLeaveRoom success")
//                completionHandler?()
            } onError: { error in
                cdPrint("requestLeaveRoom error: \(error)")
//                completionHandler?()
            }
        completionHandler?()
    }
    
    
    private func showRecommendUser(_ completionHandler: CallBack? = nil) {
        if viewModel.showRecommendUser {
            let vc = Social.LeaveGameViewController(with: self.viewModel.roomReplay.value.roomId, topicId: viewModel.roomReplay.value.topicId)
            navigationController?.pushViewController(vc, completion: { [weak self] in
                completionHandler?()
                guard let `self` = self else { return }
                self.navigationController?.viewControllers.removeAll(self)
            })
        } else {
            dismissViewController(completionHandler: {
                completionHandler?()
            })
        }
        Social.ShareRoomViewController.clear()
    }
    
    
    func dismissViewController(completionHandler: CallBack? = nil) {
        navigationController?.popViewController(animated: true) {
            completionHandler?()
            
        }
    }
}


extension AmongChat.GroupRoom.ViewController {
    
    // MARK: -
    
    private func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hex6: 0x00011B)
                
        topBar = AmongGroupTopView(room)
//        configView = AmongChatRoomConfigView(room)
        
        amongInputCodeView = AmongInputCodeView()
        amongInputCodeView.alpha = 0
        
        bottomBar = AmongRoomBottomBar()
        bottomBar.isMicOn = true
        bottomBar.update(room)
        
        nickNameInputView = AmongInputNickNameView()
        nickNameInputView.alpha = 0
        
        inputNotesView = AmongInputNotesView()
        inputNotesView.alpha = 0
                
        topEntranceView = AmongChat.Room.TopEntranceView()
        topEntranceView.isUserInteractionEnabled = false
        
        view.addSubviews(views: bgView, messageView, hostView, seatView, messageInputContainerView, amongInputCodeView, topBar,
//                         toolView,
                         bottomBar, nickNameInputView, inputNotesView, topEntranceView)
        
        topBar.snp.makeConstraints { maker in
            maker.left.top.right.equalToSuperview()
            maker.height.equalTo(150 + Frame.Height.safeAeraTopHeight)
        }
        
//        configView.snp.makeConstraints { maker in
//            maker.left.right.equalToSuperview()
//            maker.top.equalTo(topBar.snp.bottom)
//            maker.height.equalTo(125)
//        }
        
        bgView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        let hostViewTopEdge = Frame.Height.deviceDiagonalIsMinThan4_7 ? 0 : 25
        hostView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topBar.snp.bottom).offset(hostViewTopEdge)
            maker.height.equalTo(125.5)
        }

        seatView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(hostView.snp.bottom)
            maker.height.equalTo(251)
        }
        
        let messageViewTopEdge = Frame.Height.deviceDiagonalIsMinThan4_7 ? 0 : 17
        messageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(seatView.snp.bottom).offset(messageViewTopEdge)
            maker.bottom.equalTo(bottomBar.snp.top).offset(-10)
            maker.left.right.equalToSuperview()
        }
        
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
        
        topEntranceView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topBar.snp.top)
            maker.height.equalTo(44)
        }

    }
    
    private func bindSubviewEvent() {
        startRtcAndImService()

        RxKeyboard.instance.isHidden
            .asObservable()
            .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] isHidden in
                self?.isKeyboardVisible = !isHidden
                if isHidden {
                    self?.keyboardHiddenBlock?()
                    self?.keyboardHiddenBlock = nil
                }
            })
            .disposed(by: bag)
        
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
        
        viewModel.roomReplay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] room in
                self?.room = room
                self?.topBar.set(room)
//                self?.configView.room = room
                self?.bottomBar.update(room)
//                self?.toolView.set(room)
                self?.seatView.room = room
                //update list and other
//                self?.userCollectionView.reloadData()
            })
            .disposed(by: bag)
        
        viewModel.soundAnimationIndex
            .bind(to: seatView.rx.soundAnimation)
            .disposed(by: bag)

        messageView.bind(dataSource: viewModel)
        
        viewModel.endRoomHandler = { [weak self] action in
            guard let `self` = self else { return }
            switch action {
            case .kickout(let role):
                self.requestLeaveRoom { [weak self] in
//                    self?.showRecommendUser()
                    self?.dismissViewController(completionHandler: {
//                        completionHandler?()
                        let vc = UIApplication.navigationController?.viewControllers.last
                        vc?.showKickedAlert(with: role)
                    })

                }
            default:
                ()
            }
        }
        
        viewModel.followUserSuccess = { [weak self] (status, success) in
            guard let `self` = self else { return }
            let removeBlock =  self.view.raft.show(.loading)
            if status == .end {
                removeBlock()
                if success {
                    self.view.raft.autoShow(.text(R.string.localizable.socialFollowedSucess()))
                } else {
                    self.view.raft.autoShow(.text(R.string.localizable.socialFollowFailed()))
                }
            }
        }
        viewModel.blockUserResult = { [weak self](status, type, success) in
            guard let `self` = self else { return }
            let removeBlock =  self.view.raft.show(.loading)
            if status == .end {
                removeBlock()
                var message = ""
                if type == .block {
                    if success {
                        message = R.string.localizable.profileBlockUserSuccess()
                    } else {
                        message = R.string.localizable.socialBlockFailed()
                    }
                } else {
                    if success {
                        message = R.string.localizable.profileUnblockUserSuccess()
                    } else {
                        message = R.string.localizable.socialUnblockFailed()
                    }
                }
                self.view.raft.autoShow(.text(message))
            }
        }
        
        viewModel.onUserJoinedHandler = { [weak self] message in
            self?.topEntranceView.add(message.user)
        }
        
        viewModel.messageHandler = { [weak self] message in
            guard let `self` = self else {
                return
            }
            switch message.msgType {
            case .emoji:
                guard let message = message as? ChatRoom.EmojiMessage,
                      let seat = self.room.roomUserList.first(where: { $0.uid == message.user.uid }) else {
                    return
                }
                self.seatView.play(message) { [weak self] in
                    
                }
            default:
                ()
            }
        }
        //
        viewModel.addJoinMessage()
        
        viewModel.shareEventHandler = { [weak self] in
            self?.onShareBtn()
        }
        
//        configView.updateEditTypeHandler = { [weak self] editType in
//            self?.editType = editType
//        }
//
//        configView.openGameHandler = { [weak self] in
//            guard let `self` = self, self.room.topicType.productId > 0 else {
//                return
//            }
//            self.showStoreProduct(with: self.room.topicType.productId)
//            Logger.Action.log(.room_open_game, categoryValue: self.room.topicId)
//        }
//
        topBar.leaveHandler = { [weak self] in
            guard let `self` = self else { return }
            self.requestLeaveRoom { [weak self] in
                self?.showRecommendUser()
            }
        }
//
//        topBar.kickOffHandler = { [weak self] in
//            Logger.Action.log(.admin_kick_imp, categoryValue: self?.room.topicId)
//            self?.style = .kick
//        }
        
        topBar.reportHandler = { [weak self] in
            self?.showReportSheet()
        }
        
//        topBar.nextRoomHandler = { [weak self] in
//            self?.nextRoom()
//        }
        
        topBar.changePublicStateHandler = { [weak self] in
            guard let `self` = self else { return }
            self.topBar.isIndicatorAnimate = true
            self.viewModel.changePublicType { [weak self] in
                self?.topBar.isIndicatorAnimate = false
            }
            Logger.Action.log(.admin_change_state, categoryValue: self.room.state.rawValue)
        }
        
        bottomBar.sendMessageHandler = { [weak self] in
            self?.editType = .message
        }
        
        bottomBar.emojiHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            Logger.Action.log(.room_emoji_clk, categoryValue: self.room.topicId)
            let vc = AmongChat.Room.EmojiPickerController(self.emojiPickerViewModel)
            vc.didSelectItemHandler = { [weak self] emoji in
                //
                Logger.Action.log(.room_emoji_selected, categoryValue: self?.room.topicId, emoji.id.string)
                self?.viewModel.sendEmoji(emoji)
            }
            vc.showModal(in: self)

        }
        
        bottomBar.shareHandler = { [weak self] in
//            self?.editType = .message
            self?.onShareBtn()
            Logger.Action.log(.room_share_clk, categoryValue: self?.room.topicId, "btn")
        }
        
        bottomBar.changeMicStateHandler = { [weak self] micOn in
            Logger.Action.log(.room_mic_state, categoryValue: self?.room.topicId, micOn ? "on" : "off")
            self?.viewModel.isMuteMic = !micOn
        }
        
        bottomBar.cancelKickHandler = { [weak self] in
            self?.style = .normal
        }
        
        bottomBar.kickSelectedHandler = { [weak self] users in
            guard let `self` = self else { return }
            Logger.Action.log(.admin_kick_success, categoryValue: self.room.topicId)
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
            Logger.Action.log(.admin_edit_success, categoryValue: self?.room.topicId)
        }
        
        nickNameInputView.inputResultHandler = { [weak self] text in
            Logger.Action.log(.room_edit_nickname_success, categoryValue: self?.room.topicId)
            self?.viewModel.update(nickName: text)
        }
        
        inputNotesView.inputResultHandler = { [weak self] notes in
            Logger.Action.log(.admin_edit_success, categoryValue: self?.room.topicId)
            self?.viewModel.update(notes: notes)
        }
                
        seatView.selectUserHandler = { [weak self] user in
            guard let user = user else {
                Logger.Action.log(.room_share_clk, categoryValue: self?.room.topicId, "seat")
                self?.onShareBtn()
                return
            }
        }
    }
    
    func startRtcAndImService() {
        
        topBar.isIndicatorAnimate = showInnerJoinLoading
        //        view.isUserInteractionEnabled = false
        viewModel.join { [weak self] error in
            //            removeBlock()
            self?.topBar.isIndicatorAnimate = false
            //            self.view.isUserInteractionEnabled = false
            self?.showContainerLoading?(false)
            if error != nil {
                self?.requestLeaveRoom()
            }
        }
    }
    
    func nextRoom() {
        Logger.Action.log(.room_next_room_clk, categoryValue: room.topicName)
        showContainerLoading?(true)
        viewModel.nextRoom { [weak self] room, errorMsg in
            if let room = room {
                Logger.Action.log(.room_next_room_success, categoryValue: room.topicName)
                self?.switchLiveRoomHandler?(room)
            } else {
                self?.showContainerLoading?(false)
            }
        }
    }
    
    func onUserProfileSheet(action: AmongSheetController.ItemType, user: Entity.RoomUser) {
        switch action {
        case .profile:
            let vc = Social.ProfileViewController(with: user.uid)
            vc.roomUser = user
            navigationController?.pushViewController(vc)
        case .follow:
            viewModel.followUser(user)
        case .block:
            viewModel.blockedUser(user)
        case .mute:
            viewModel.muteUser(user)
        case .unblock:
            viewModel.unblockedUser(user)
        case .unmute:
            viewModel.unmuteUser(user)
        case .report:
            self.showReportSheet()
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
}

extension AmongChat.GroupRoom.ViewController {
    
}
