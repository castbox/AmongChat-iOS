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
import EasyTipView

typealias AudienceViewModel = AmongChat.GroupRoom.AudienceViewModel
typealias BroadcasterViewModel = AmongChat.GroupRoom.BroadcasterViewModel

extension AmongChat.GroupRoom {
        
    class ViewController: WalkieTalkie.ViewController, GestureBackable {
        
        var isEnableScreenEdgeGesture: Bool = false
        
        private typealias UserCell = AmongChat.Room.UserCell
        
        private var room: Entity.Group
        
        //
        private let viewModel: BaseViewModel
        //
        var audienceViewModel: AudienceViewModel? { viewModel as? AudienceViewModel }
        var broadcasterViewModel: BroadcasterViewModel? { viewModel as? BroadcasterViewModel }

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
                    Logger.Action.log(.group_edit_nickname, categoryValue: room.topicId)
                case .chillingSetup:
                    self.view.bringSubviewToFront(inputNotesView)
                    inputNotesView.placeHolder = R.string.localizable.roomSetupHostNotes()
                    inputNotesView.notes = room.note
                    inputNotesView.isLinkContent = false
                    inputNotesView.show(with: room)
                    Logger.Action.log(.group_edit_clk, categoryValue: room.topicId)
                case .robloxSetup:
                    self.view.bringSubviewToFront(inputNotesView)
//                    inputNotesView.notes = room.robloxLink
                    inputNotesView.placeHolder = R.string.localizable.groupRoomSetUpLink()
                    inputNotesView.isLinkContent = true
                    inputNotesView.show(with: room)
                    Logger.Action.log(.admin_edit_imp, categoryValue: room.topicId)
                default:
                    Logger.Action.log(.group_send_message_clk, categoryValue: self.room.topicId)
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
        
        lazy var hostView = AmongGroupHostView(group: room, viewModel: viewModel)
        private lazy var seatView: AmongChat.Room.SeatView = {
            return AmongChat.Room.SeatView(room: room, itemStyle: .group, viewModel: viewModel)
        }()
        
        private lazy var messageView = AmongChat.Room.MessageListView()
                
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
        
        private var tipView: EasyTipView?
        
        private var applyButton: FansGroup.Views.BottomGradientButton!
        
        let joinRequestViewModel: AmongChat.GroupRoom.JoinRequestViewModel
        
        override var screenName: Logger.Screen.Node.Start {
            return .room
        }
                        
        init(viewModel: BaseViewModel) {
            self.room = viewModel.roomReplay.value as! Entity.Group
            self.viewModel = viewModel
            self.joinRequestViewModel = AmongChat.GroupRoom.JoinRequestViewModel(with: viewModel.group.gid)
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
        guard socialShareViewController == nil, let name = Settings.loginUserProfile?.name else {
            return
        }
        let link = R.string.localizable.amongChatGroupShareContent(name,
                                                                   room.name,
                                                                   "https://among.chat/group?gid=\(room.roomId)") 
        let vc = Social.ShareRoomViewController(with: link, roomId: room.roomId, topicId: viewModel.roomReplay.value.topicId, isGroup: true)
        vc.showModal(in: self)

        viewModel.didShowShareView()
        socialShareViewController = vc
    }
    
    func requestLeaveRoom(completionHandler: CallBack? = nil) {
        Logger.Action.log(.group_leave_clk, categoryValue: room.topicId, nil, viewModel.stayDuration)
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
//        if viewModel.showRecommendUser {
//            let vc = Social.LeaveGameViewController(with: self.viewModel.roomReplay.value.roomId, topicId: viewModel.roomReplay.value.topicId)
//            navigationController?.pushViewController(vc, completion: { [weak self] in
//                completionHandler?()
//                guard let `self` = self else { return }
//                self.navigationController?.viewControllers.removeAll(self)
//            })
//        } else {
            dismissViewController(completionHandler: {
                completionHandler?()
            })
//        }
        Social.ShareRoomViewController.clear()
    }
    
    
    func dismissViewController(completionHandler: CallBack? = nil) {
        navigationController?.popViewController(animated: true) {
            completionHandler?()
            
        }
    }
}


extension AmongChat.GroupRoom.ViewController {
    
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
                case .chillingSetup, .robloxSetup:
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
            .map { $0 as? Entity.Group }
            .filterNil()
            .subscribe(onNext: { [weak self] room in
//                guard let room = room else {
//                    return
//                }
                self?.room = room
                self?.topBar.set(room)
                self?.hostView.group = room
//                self?.configView.room = room
                self?.bottomBar.update(room)
//                self?.toolView.set(room)
                self?.seatView.room = room
                //update list and other
//                self?.userCollectionView.reloadData()
            })
            .disposed(by: bag)
        
        viewModel.seatDataSourceReplay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] dataSource in
                self?.seatView.dataSource = dataSource
            })
            .disposed(by: bag)
        
        viewModel.listenerListReplay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] dataSource in
                self?.topBar.listenerList = dataSource
            })
            .disposed(by: bag)
        
        viewModel.listenerCountReplay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] count in
                self?.topBar.listenerCount = count
            })
            .disposed(by: bag)
        
        viewModel.broadcasterReplay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] user in
                self?.hostView.hostProfile = user
            })
            .disposed(by: bag)

        viewModel.soundAnimationIndex
            .do(onNext: { [weak self] index in
                guard index == -1 else {
                    return
                }
                self?.hostView.startSoundAnimation()
            })
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
            case .normalClose:
                self.requestLeaveRoom { [weak self] in
//                    self?.showRecommendUser()
                    self?.dismissViewController(completionHandler: {
//                        completionHandler?()
                        let vc = UIApplication.navigationController?.viewControllers.last
                        vc?.view.raft.autoShow(.text(R.string.localizable.groupRoomEndTips()))
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
        
        viewModel.onUserJoinedHandler = { [weak self] user in
            self?.topEntranceView.add(user)
        }
        
        viewModel.messageHandler = { [weak self] message in
            guard let `self` = self else {
                return
            }
            switch message.msgType {
            case .emoji:
                guard let message = message as? ChatRoom.EmojiMessage,
                      let seat = self.room.userList.first(where: { $0.uid == message.user.uid }) else {
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
        
        viewModel.groupInfoReplay
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] info in
                self?.applyButton.setTitle(info.titleForApplyButton, for: .normal)
                self?.applyButton.isHidden = !info.showApplyButton
                self?.applyButton.isEnabled = info.userStatusEnum == .some(.none)
            })
            .disposed(by: bag)


//        configView.updateEditTypeHandler = { [weak self] editType in
//            self?.editType = editType
//        }
//
//        configView.openGameHandler = { [weak self] in
//            guard let `self` = self, self.room.topicType.productId > 0 else {
//                return
//            }
//            self.showStoreProduct(with: self.room.topicType.productId)
//            Logger.Action.log(.group_open_game, categoryValue: self.room.topicId)
//        }
//
//        topBar.leaveHandler = { [weak self] in
//            guard let `self` = self else { return }
//            self.requestLeaveRoom { [weak self] in
//                self?.showRecommendUser()
//            }
//        }
        
        
        topBar.actionHandler = { [weak self] type in
            guard let `self` = self else { return }
            switch type {
            case .leave:
                self.requestLeaveRoom { [weak self] in
                    self?.showRecommendUser()
                }
            case .topic:
                guard self.viewModel.group.loginUserIsAdmin else {
                    self.view.raft.autoShow(.text(R.string.localizable.groupRoomAudienceChangeTopicTips()))
                    return
                }
                let vc = FansGroup.AddTopicViewController(self.room.topicId)
                vc.topicSelectedHandler = { [weak self] topic in
                    //update topic
                    self?.viewModel.update(topicId: topic.topic.topicId)
                }
                self.presentPanModal(vc)
            case .memberList:
                Logger.Action.log(.group_member_list_imp, categoryValue: self.room.topicId)
                let vc = AmongChat.GroupRoom.MembersController(with: self.room.gid)
                self.presentPanModal(vc)
            case .groupInfo:
                Logger.Action.log(.group_cover_clk, categoryValue: self.room.topicId)
                let vc = FansGroup.GroupInfoViewController(groupId: self.room.gid)
                self.navigationController?.pushViewController(vc, animated: true)
            case .setupCode:
                self.editType = .amongSetup
            case .setupLink:
                self.editType = .robloxSetup
            case .setupNotes:
                self.editType = .chillingSetup
            
            }
        }
        
        topBar.reportHandler = { [weak self] in
            self?.showReportSheet()
        }
        
        hostView.actionHandler = { [weak self] type in
            guard let `self` = self else { return }
            switch type {
            case .editNickName:
                self.editType = .nickName
            case .joinGroup:
                Logger.Action.log(.group_broadcaster_join_request_imp, categoryValue: self.room.topicId)
                let vc = AmongChat.GroupRoom.JoinRequestListController(with: self.room.topicId, viewModel: self.joinRequestViewModel)
                self.presentPanModal(vc)
            case .joinHost:
                //data source
                guard let replay = self.broadcasterViewModel?.callInListReplay else {
                    return
                }
                Logger.Action.log(.group_broadcaster_raise_hands_imp, categoryValue: self.room.topicId)
                let vc = AmongChat.GroupRoom.SeatRequestListController(with: self.room, replay: replay)
                vc.actionHandler = { [weak self, weak vc] user, action in
                    guard let `self` = self else { return }
                    switch action {
                    case .accept:
                        let removeHandler = vc?.view.raft.show(.loading)
                        self.broadcasterViewModel?.requestGroupRoomSeatAdd(for: user)
                            .subscribe(onSuccess: { [weak self] result in
                                removeHandler?()
                                self?.broadcasterViewModel?.sendCallSignal(isAccept: true, user)
                            }, onError: { [weak self] error in
                                removeHandler?()
                                self?.view.raft.autoShow(.text(R.string.localizable.serverLostTips()))
                            })
                            .disposed(by: self.bag)
                    case .reject:
                        self.broadcasterViewModel?.sendCallSignal(isAccept: false, user)
                    }
                    
                }
                self.presentPanModal(vc)
            case let .userProfileSheetAction(item, user):
                self.onUserProfileSheet(action: item, user: user)
            }
        }
        
        joinRequestViewModel.countReplay
            .subscribe(onNext: { [weak self] count in
                self?.hostView.updateApplyGroupBadge(with: count)
            })
            .disposed(by: bag)
        
        bottomBar.sendMessageHandler = { [weak self] in
            self?.editType = .message
        }
        
//        bottomBar.emojiHandler = { [weak self] in
//            guard let `self` = self else {
//                return
//            }
//            Logger.Action.log(.group_emoji_clk, categoryValue: self.room.topicId)
//            let vc = AmongChat.Room.EmojiPickerController(self.emojiPickerViewModel)
//            vc.didSelectItemHandler = { [weak self] emoji in
//                //
//                Logger.Action.log(.group_emoji_selected, categoryValue: self?.room.topicId, emoji.id.string)
//                self?.viewModel.sendEmoji(emoji)
//            }
//            vc.showModal(in: self)
//
//        }
        
        bottomBar.shareHandler = { [weak self] in
//            self?.editType = .message
            self?.onShareBtn()
            Logger.Action.log(.group_share_clk, categoryValue: self?.room.topicId, "btn")
        }
        
        bottomBar.changeMicStateHandler = { [weak self] micOn in
            Logger.Action.log(.group_mic_state, categoryValue: self?.room.topicId, micOn ? "on" : "off")
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
        
        seatView.actionHandler = { [weak self] action in
            switch action {
            case .editGameName:
                self?.editType = .nickName
            case .selectUser(let user):
                guard let user = user else {
                    Logger.Action.log(.group_share_clk, categoryValue: self?.room.topicId, "seat")
                    self?.onShareBtn()
                    return
                }
                ()
            case .requestOnSeat(let position):
                //判断关系
                guard self?.viewModel.groupInfo.userStatusEnum == .some(.memeber) else {
                    //
                    self?.view.raft.autoShow(.text(R.string.localizable.groupRoomAnoymonusUserApplySeatTips()))
                    return
                }
                Logger.Action.log(.group_audience_raise_hands_clk, categoryValue: self?.room.topicId, "seat")
                self?.audienceViewModel?.requestOnSeat(at: position)
            case .selectedKickUser(let users):
                self?.bottomBar.selectedKickUser = users
            case let .userProfileSheetAction(item, user):
                self?.onUserProfileSheet(action: item, user: user)
            }
        }
        
        
//        seatView.selectUserHandler = { [weak self] user in
//            guard let user = user else {
//                Logger.Action.log(.group_share_clk, categoryValue: self?.room.topicId, "seat")
//                self?.onShareBtn()
//                return
//            }
//        }
//
//        seatView.requestOnSeatHandler = { [weak self] position in
//            //判断关系
//            guard self?.viewModel.groupInfo.userStatusEnum == .some(.memeber) else {
//                //
//                self?.view.raft.autoShow(.text(R.string.localizable.groupRoomAnoymonusUserApplySeatTips()))
//                return
//            }
//            self?.audienceViewModel?.requestOnSeat(at: position)
//        }

        
        amongInputCodeView.inputResultHandler = { [weak self] code, aera in
            self?.viewModel.updateAmong(code: code, aera: aera)
            Logger.Action.log(.group_amongus_code_set_done, categoryValue: self?.room.topicId)
        }
        
        nickNameInputView.inputResultHandler = { [weak self] text in
            Logger.Action.log(.group_edit_nickname_success, categoryValue: self?.room.topicId)
            self?.viewModel.update(nickName: text)
        }
        
        inputNotesView.inputResultHandler = { [weak self] notes in
            if self?.room.topicType == .roblox {
                Logger.Action.log(.group_roblox_link_set_done, categoryValue: self?.room.topicId)
            } else {
                Logger.Action.log(.group_notes_set_done, categoryValue: self?.room.topicId)
            }
            self?.viewModel.update(notes: notes)
        }
                
        applyButton.actionHandler = { [weak self] in
            Logger.Action.log(.group_apply_join_clk, categoryValue: self?.room.topicId)
            self?.applyJoinGroup()
        }
        
        bindCallEvent()
    }
    
    func applyJoinGroup() {
        let hudRemoval = self.view.raft.show(.loading)
        audienceViewModel?.applyJoinGroup()
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (_) in
//                self?.bottomGradientView.isHidden = true
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
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
        case .drop:
            requestSeats(remove: user.uid)
        default:
            ()
        }
    }
    
    func requestSeats(remove uid: Int) {
        if viewModel.group.loginUserIsAdmin == true {
            //踢人
           broadcasterViewModel?.rejectCall(uid: uid)
        }
        else {
            //下麦
            //                    self?.audienceViewModel?.phoneCallHangUpBySelf()
        }
        let removeBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
        viewModel.requestSeats(remove: uid)
            .subscribe { [weak self] result in
                removeBlock()
            } onError: { [weak self] error in
                removeBlock()
                self?.view.raft.autoShow(.text(R.string.localizable.serverLostTips()))
            }
            .disposed(by: self.bag)
    }
    
    func requestKick(_ users: [Int]) {
        let removeBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
//        self.viewModel.requestKick(users)
//            .subscribe { [weak self] result in
//                removeBlock()
//                self?.style = .normal
//            } onError: { error in
//                removeBlock()
//            }
//            .disposed(by: self.bag)
    }
    
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
        
        applyButton = FansGroup.Views.BottomGradientButton()
//        applyButton.setTitle(viewModel.groupInfo.titleForApplyButton, for: .normal)
        applyButton.isHidden = true
//        applyButton.isEnabled = !viewModel.groupInfo.showApplyButton
        
        view.addSubviews(views: bgView, messageView, hostView, seatView, messageInputContainerView, amongInputCodeView, topBar,
//                         toolView,
                         bottomBar, applyButton, nickNameInputView, inputNotesView, topEntranceView)
        
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
            maker.height.equalTo(AmongChat.Room.SeatView.itemHeight * 2)
        }
        
        messageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(seatView.snp.bottom)
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
            maker.top.equalTo(topBar.snp.bottom).offset(12)
            maker.height.equalTo(44)
        }
        
        applyButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(100 + Frame.Height.safeAeraBottomHeight)
        }

    }
}

extension AmongChat.GroupRoom.ViewController {
    
}

//MARK: - For Audience
private extension AmongChat.GroupRoom.ViewController {
    
    func showToast(with string: String?) {
        guard let msg = string else {
            return
        }
        view.raft.autoShow(.text(msg))
    }
    
    func onReceiveCalling(message: Peer.CallMessage, rejectType: PhoneCallRejectType) {
        // 主播拒绝callin
        if rejectType != .none {
//            if message.action == .hangup {
//                //连麦后被下麦
//                showToast(with: R.string.localizable.groupRoomAudienceDropedTips())
//            } else {
            showToast(with: rejectType.message)
//            }
            audienceViewModel?.clearSeatCallState()
            bottomBar.isMicButtonHidden = true
        } else {// 主播同意callin
            if audienceViewModel?.phoneCallState == .calling {
                audienceViewModel?.updateOnSeatState(with: message)
                bottomBar.isMicButtonHidden = false
            } else if audienceViewModel?.phoneCallState == .readyForCall {// 听众hangup
                audienceViewModel?.clearSeatCallState()
            }
        }

    }
    
    func bindCallEvent() {
        //
        bottomBar.isMicButtonHidden = !room.loginUserIsAdmin
        audienceViewModel?.callingHandler = { [weak self] rejectType, call in
            //            guard let `self` = self else { return }
            self?.onReceiveCalling(message: call, rejectType: rejectType)
            
        }
        
        broadcasterViewModel?.callInListReplay
            .subscribe(onNext: { [weak self] users in
                self?.hostView.updateOnSeatBadge(with: users.count)
            })
            .disposed(by: bag)
    }
}
