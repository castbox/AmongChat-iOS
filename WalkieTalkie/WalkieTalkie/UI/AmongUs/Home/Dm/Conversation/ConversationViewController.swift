//
//  ConversationViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SDCAlertView

private let bottomBarHeight: CGFloat = 64 + Frame.Height.safeAeraBottomHeight
private let collectionBottomEdge: CGFloat = 64 + 18 + Frame.Height.safeAeraBottomHeight
private let messagePageLimit = 50

class ConversationViewController: ViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var navBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var userInfostackView: UIStackView!
    
    @IBOutlet private weak var onlineView: UIView!
    
    private var liveContainer: UIView!
    private var liveView: Social.ProfileViewController.LiveCell!
    
    private lazy var bottomBar = ConversationBottomBar()
    
    private var conversation: Entity.DMConversation
    private let viewModel: Conversation.ViewModel
    private var relationData: Entity.RelationData?
    private var blocked = false
    private var firstDataLoaded: Bool = true
    //count changed
    private var lastCount: Int = 0
    private var lastMessageMs: Double = 0
    private var isFirstShowFollow: Bool = true
    private var keyboardVisibleHeight: CGFloat = 0
    private var hasEarlyMessage = false
    private var hasTriggeredLoadEarly = false
    
    private var dataSource: [Conversation.MessageCellViewModel] = [] {
        didSet {
            updateContentInset()
        }
    }
    
    var followedHandle:((Bool) -> Void)?
    
    deinit {
        AudioPlayerManager.default.stopPlay()
    }
    
    init(_ conversation: Entity.DMConversation) {
        self.conversation = conversation
        self.viewModel = Conversation.ViewModel(conversation)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        removeDuplicateConversation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
    }
    
    func showReportSheet() {
        Report.ViewController.showReport(on: self, uid: viewModel.targetUid, type: .user, roomId: "", operate: nil) { [weak self] in
            self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController()
    }
    
    @IBAction func moreButtonAction(_ sender: Any) {
        view.endEditing(true)
        moreAction()
    }
    
    @IBAction func followButtonAction(_ sender: Any) {
        followAction()
    }
    
}


extension ConversationViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = dataSource.safe(indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: ConversationCollectionCell.self, for: indexPath)
        cell.bind(item)
        cell.actionHandler = { [weak self] action in
            switch action {
            case .resend(let message):
                self?.sendMessage(message)
                Logger.Action.log(.dm_detail_item_clk, categoryValue: "resend")
            case .clickVoiceMessage(let message):
                self?.viewModel.clearUnread(message)
                Logger.Action.log(.dm_detail_item_clk, categoryValue: "voice_play")
            case .user(let uid):
                let vc = Social.ProfileViewController(with: uid.string.intValue)
                vc.followedHandle = { [weak self] follow in
                    self?.relationData?.isFollowed = follow
                    self?.setFollowButton(follow, isHidden: false)
                }
                self?.navigationController?.pushViewController(vc)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: Conversation.HeaderLoadingView.self, for: indexPath)
        if hasEarlyMessage {
            view.indicator.startAnimating()
        } else {
            view.indicator.stopAnimating()
        }
        return view
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if hasEarlyMessage,
           scrollView.contentOffset.y <= 0,
           !hasTriggeredLoadEarly {
            hasTriggeredLoadEarly = true
            loadMore()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if bottomBar.isFirstResponder {
            view.endEditing(true)
        }
    }
}

extension ConversationViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let viewModel = dataSource.safe(indexPath.item) else {
            return .zero
        }
        
        return CGSize(width: Frame.Screen.width, height: viewModel.height)
    }
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard hasEarlyMessage else {
            return .zero
        }
        return CGSize(width: Frame.Screen.width, height: 40)
    }
}

extension ConversationViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.safe(indexPath.item) else {
            return
        }
        //        let vc = ConversationViewController(item)
        //        navigationController?.pushViewController(vc)
    }
    
}

//requet
private extension ConversationViewController {
    func fetchUserStatus() {
        Request.userStatus(viewModel.targetUid.intValue)
            .subscribe(onSuccess: { [weak self] (status) in
                
                guard let `self` = self, let status = status else { return }
                
                if let room = status.room {
                    self.liveView.coverIV.setImage(with: room.coverUrl)
                    self.liveView.label.text = R.string.localizable.profileUserInChannel(room.topicName)
                    self.liveView.joinBtn.isEnabled = (room.state != "private")
                    self.liveView.joinHandler = { [weak self] in
                        self?.enterRoom(roomId: room.roomId, topicId: room.topicId)
                        Logger.Action.log(.dm_detail_clk, categoryValue: "join_channel")
                    }
                } else if let group = status.group {
                    self.liveView.coverIV.setImage(with: group.cover)
                    self.liveView.label.text = R.string.localizable.profileUserInGroup(group.name)
                    self.liveView.joinBtn.isEnabled = true
                    self.liveView.joinHandler = { [weak self] in
                        self?.enter(group: group.gid)
                        Logger.Action.log(.dm_detail_clk, categoryValue: "join_group")
                    }
                }
                let isHiddenLiveContainer = status.room == nil && status.group == nil
                if !isHiddenLiveContainer {
                    self.liveContainer.fadeIn(duration: 0.2)
                } 
                self.updateUser(isOnline: status.isOnline == true && self.liveContainer.isHidden)
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
    func updateUser(isOnline: Bool) {
        //        if isOnline {
        //            onlineView.fadeIn(duration: 0.2)
        //        } else {
        //            onlineView.fadeOut(duration: 0.2)
        //        }
        onlineView.isHidden = !isOnline
        updateContentInset()
    }
    
    func fetchRealation() {
        Request.relationData(uid: viewModel.targetUid.intValue)
            .subscribe(onSuccess: { [weak self] (data) in
                guard let `self` = self, let data = data else { return }
                self.relationData = data
                self.blocked = data.isBlocked ?? false
                let follow = data.isFollowed ?? false
                self.setFollowButton(follow)
            }, onError: { (error) in
                cdPrint("relationData error :\(error.localizedDescription)")
            }).disposed(by: bag)
    }
    
    func blockUser() {
        let removeBlock = view.raft.show(.loading)
        if blocked {
            Request.unFollow(uid: viewModel.targetUid.intValue, type: "block")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.handleBlockResult(isBlocked: false)
                    }
                    removeBlock()
                }, onError: { (error) in
                    removeBlock()
                    
                }).disposed(by: bag)
        } else {
            Request.follow(uid: viewModel.targetUid.intValue, type: "block")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.handleBlockResult(isBlocked: true)
                    }
                    removeBlock()
                }, onError: { (error) in
                    removeBlock()
                }).disposed(by: bag)
        }
    }
    
    func handleBlockResult(isBlocked: Bool) {
        var blockedUsers = Defaults[\.blockedUsersV2Key]
        if isBlocked {
            blocked = true
            let user = conversation.message.fromUser
            if !blockedUsers.contains(where: { $0.uid == viewModel.targetUid.intValue }) {
                let newUser = Entity.RoomUser(uid: viewModel.targetUid.intValue, name: user.name ?? "", pic: user.pictureUrl ?? "")
                blockedUsers.append(newUser)
                Defaults[\.blockedUsersV2Key] = blockedUsers
            }
            view.raft.autoShow(.text(R.string.localizable.profileBlockUserSuccess()))
        } else {
            blocked = false
            blockedUsers.removeElement(ifExists: { $0.uid == viewModel.targetUid.intValue })
            Defaults[\.blockedUsersV2Key] = blockedUsers
            view.raft.autoShow(.text(R.string.localizable.profileUnblockUserSuccess()))
        }
    }
    
    func followAction() {
        let removeBlock = view.raft.show(.loading)
        let isFollowed = relationData?.isFollowed ?? false
        if isFollowed {
            Logger.Action.log(.dm_detail_clk, categoryValue: "unfollow")
            Request.unFollow(uid: viewModel.targetUid.intValue, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    guard let `self` = self else { return }
                    removeBlock()
                    if success {
                        self.fetchRealation()
                        self.relationData?.isFollowed = false
                        self.setFollowButton(false)
                        self.followedHandle?(false)
                    }
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("unfollow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        } else {
            Logger.Action.log(.dm_detail_clk, categoryValue: "follow")
            Request.follow(uid: viewModel.targetUid.intValue, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    guard let `self` = self else { return }
                    removeBlock()
                    if success {
                        self.fetchRealation()
                        self.relationData?.isFollowed = true
                        self.setFollowButton(true)
                        self.followedHandle?(true)
                    }
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("follow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        }
    }
    
    func updateProfile() {
        Request.profile(viewModel.targetUid.intValue)
            .subscribe(onSuccess: { [weak self] profile in
                self?.titleLabel.text = profile?.name
            }, onError: { error in
                
            })
            .disposed(by: bag)
    }
    
    func sendMessage(_ text: String) {
//        guard var message = viewModel.message(for: text) else {
//            return
//        }
//        DMManager.shared.insertOrReplace(message: message)
//        //insert cell
//        dataSource.insert(<#T##newElement: Conversation.MessageCellViewModel##Conversation.MessageCellViewModel#>, at: <#T##Int#>)
        self.viewModel.sendMessage(text)
            .subscribe(onSuccess: { result in
                
            }) { [weak self] error in
                self?.showBeblockedErrorTipsIfNeed(error)
            }
            .disposed(by: bag)
    }
    
    func sendMessage(_ message: Entity.DMMessage) {
        self.viewModel.sendMessage(message)
            .subscribe(onSuccess: { result in
                
            }) { [weak self] error in
                self?.showBeblockedErrorTipsIfNeed(error)
            }
            .disposed(by: bag)
    }
    
    func sendVoiceMessage(duration: Int, filePath: String) {
        viewModel.sendVoiceMessage(duration: duration, filePath: filePath)
            .subscribe(onSuccess: { result in
                
            }) { [weak self] error in
                self?.showBeblockedErrorTipsIfNeed(error)
            }
            .disposed(by: bag)
    }
    
    func sendGif(_ media: Giphy.GPHMedia) {
        viewModel.sendGif(media)
            .subscribe(onSuccess: { result in
                
            }) { [weak self] error in
                self?.showBeblockedErrorTipsIfNeed(error)
            }
            .disposed(by: bag)
        
    }
    
    func showBeblockedErrorTipsIfNeed(_ error: Error) {
        guard let msgError = error as? MsgError,
              msgError.codeType == .beBlocked else {
            return
        }
        let offset = keyboardVisibleHeight > 0 ? (Frame.Screen.height - keyboardVisibleHeight) / 4 : 0
        view.raft.autoShow(.text(msgError.codeType?.tips ?? ""), userInteractionEnabled: false, offset: CGPoint(x: 0, y: -offset))
    }
    
}

private extension ConversationViewController {
    
    func removeDuplicateConversation() {
        if let nav = navigationController,
           let conVc = nav.viewControllers.first(where: { $0 is ConversationViewController }),
           conVc != self {
            nav.viewControllers = nav.viewControllers.removeAll(conVc)
        }
    }
    
    func clearAllMessage() {
        let removeBlock = view.raft.show(.loading)
        viewModel.clearAllMessage()
            .subscribe(onSuccess: { [weak self] in
                removeBlock()
                self?.updateContentInset()
            }) { error in
                removeBlock()
            }
            .disposed(by: bag)
    }
    
    func moreAction() {
        var type:[AmongSheetController.ItemType]!
        if blocked {
            type = [.unblock, .report, .dmDeleteHistory, .cancel]
        } else {
            type = [.block, .report, .dmDeleteHistory, .cancel]
        }
        AmongSheetController.show(items: type, in: self, uiType: .profile) { [weak self](type) in
            switch type {
            case.report:
                self?.showReportSheet()
                Logger.Action.log(.dm_detail_clk, categoryValue: "report")
            case .block, .unblock:
                self?.showBlockAlter()
                if type == .block {
                    Logger.Action.log(.dm_detail_clk, categoryValue: "block")
                } else if type == .unblock {
                    Logger.Action.log(.dm_detail_clk, categoryValue: "unblock")
                }
            case .dmDeleteHistory:
                self?.showDeleteHistoryAlter()
                Logger.Action.log(.dm_detail_clk, categoryValue: "delete_history")
            default:
                break
            }
        }
    }
    
    func showDeleteHistoryAlter() {
        showAmongAlert(title: R.string.localizable.dmDeleteHistoryAlertTitle(),
                       cancelTitle: R.string.localizable.toastCancel(),
                       confirmTitle: R.string.localizable.groupRoomYes(),
                       confirmTitleColor: "#FB5858".color(),
                       confirmAction: { [weak self] in
                        self?.clearAllMessage()
                       })
    }
    
    func showBlockAlter() {
        var message = R.string.localizable.profileBlockMessage()
        var confirmString = R.string.localizable.alertBlock()
        if blocked {
            message = R.string.localizable.profileUnblockMessage()
            confirmString = R.string.localizable.alertUnblock()
        }
        showAmongAlert(title: message, message: nil,
                       cancelTitle: R.string.localizable.toastCancel(),
                       confirmTitle: confirmString, confirmAction: { [weak self] in
                        self?.blockUser()
                       })
    }
    
    
    func setFollowButton(_ isFollowed: Bool, isHidden: Bool? = nil) {
        if isFollowed {
            greyFollowButton()
        } else {
            yellowFollowButton()
        }
        if let isHidden = isHidden {
            followButton.isHidden = isHidden
            followButton.isEnabled = !isHidden
        } else {
            followButton.isHidden = isFirstShowFollow && isFollowed
            isFirstShowFollow = false
            followButton.isEnabled = !isFollowed
        }
    }
    
    private func greyFollowButton() {
        followButton.setTitle(R.string.localizable.profileFollowing(), for: .normal)
        followButton.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
        followButton.layer.borderWidth = 2
        followButton.layer.borderColor = UIColor(hex6: 0x898989).cgColor
        //        followButton.backgroundColor = UIColor.theme(.backgroundBlack)
    }
    
    private func yellowFollowButton() {
        followButton.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
        followButton.layer.borderWidth = 2
        followButton.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
        followButton.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
    }
    
    func reloadCollectionView() {
        guard !dataSource.isEmpty else {
            collectionView.reloadData()
            return
        }
        let contentHeight = collectionView.contentSize.height
        let height = collectionView.bounds.size.height - collectionView.contentInset.top
        let contentOffsetY = collectionView.contentOffset.y
        let bottomOffset = contentHeight - contentOffsetY
        // 消息不足一屏
        if contentHeight < height {
            let messageHeight = dataSource.map { $0.height }.reduce(0, { $0 + $1 })
            let autoScrollToBottom = messageHeight > height
            UIView.animate(withDuration: 0) {
                self.collectionView.reloadData()
            } completion: { _ in
                //内容超过一屏
                if autoScrollToBottom {
//                    self.messageListScrollToBottom(animated: self.keyboardVisibleHeight > 0)
                    self.messageListScrollToBottom(animated: self.keyboardVisibleHeight > 0)
                }
                //首次 alpha = 0 来规避屏幕闪烁
                self.collectionView.alpha = 1
            }
        } else {// 超过一屏
            //收到新消息
            if (dataSource.last?.ms ?? 0) > lastMessageMs {
                if floor(bottomOffset) - floor(height) < 40 {
                    let rows = collectionView.numberOfItems(inSection: 0)
                    let newRow = dataSource.count
                    guard newRow > rows else {
                        lastMessageMs = (dataSource.last?.ms ?? 0)
                        reloadAndScrollToBottom()
                        return
                    }
                    let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                    collectionView.performBatchUpdates {
                        self.collectionView.insertItems(at: indexPaths)
                    } completion: { result in
                        if let endPath = indexPaths.last {
                            self.collectionView.scrollToItem(at: endPath, at: .bottom, animated: true)
                        }
                    }
                } else {
                    //检查最后一个是否为自己消息
                    reloadAndScrollToBottom()
                }
            } else {
                let indexPaths = collectionView.indexPathsForVisibleItems
//                let newRow = dataSource.count
//                guard newRow > rows else {
//                    lastMessageMs = (dataSource.last?.ms ?? 0)
//                    reloadAndScrollToBottom()
//                    return
//                }
//                let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                
                collectionView.performBatchUpdates {
//                    self.collectionView.insertItems(at: indexPaths)
                    self.collectionView.reloadItems(at: indexPaths)
                } completion: { result in
//                    if let endPath = indexPaths.last {
//                        self.collectionView.scrollToItem(at: endPath, at: .bottom, animated: true)
//                    }
                }
//                collectionView.reloadDataAndKeepOffset()
//                collectionView.reloadData()
            }
        }
//        lastCount = dataSource.count
        lastMessageMs = (dataSource.last?.ms ?? 0)
    }
    
    func reloadAndScrollToBottom() {
        if dataSource.last?.sendFromMe == true {
            UIView.animate(withDuration: 0) {
                self.collectionView.reloadData()
            } completion: { _ in
                self.messageListScrollToBottom()
            }
        } else {
            collectionView.reloadData()
        }

    }
    
    func showGifViewController() {
        let gifVc = Giphy.GifsViewController()
        gifVc.selectAction = { [weak self] media in
            self?.sendGif(media)
            Logger.Action.log(.dm_detail_send_msg, categoryValue: "gif", self?.conversation.fromUid)
            Logger.Action.log(.gif_select_clk, categoryValue: media.id)
        }
        presentPanModal(gifVc)
    }
    
    func updateContentInset() {
        let contentHeight = dataSource.reduce(0) { $0 + $1.height }
        //top insert
        let onlineViewContentHeight: CGFloat = liveContainer.isHidden ? 0 : 80
        var topInset = onlineViewContentHeight
        if topInset < 0 {
            topInset = 0
        }
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    func messageListScrollToBottom(animated: Bool = true) {
        let rows = collectionView.numberOfItems(inSection: 0)
        if rows > 0 {
            let endPath = IndexPath(row: rows - 1, section: 0)
            collectionView.scrollToItem(at: endPath, at: .bottom, animated: animated)
        }
    }
    
    func configureSubview() {
        
        liveContainer = UIView()
        liveContainer.alpha = 0
        liveContainer.backgroundColor = "121212".color()
        liveContainer.isHidden = true
        liveView = Social.ProfileViewController.LiveCell()
        
        view.addSubviews(views: bottomBar, liveContainer)
        
        bottomBar.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(bottomBarHeight)
        }
        
        liveContainer.snp.makeConstraints { (maker) in
            maker.top.equalTo(Frame.Height.navigation)
            maker.centerX.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.height.equalTo(80)
        }
        
        liveContainer.addSubview(liveView)
        liveView.snp.makeConstraints { (maker) in
            maker.top.equalTo(12)
            maker.centerX.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-20)
            maker.height.equalTo(56)
        }
        
        
//        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
        titleLabel.text = conversation.message.fromUser.name
        collectionViewBottomConstraint.constant = collectionBottomEdge
        navBarHeightConstraint.constant = Frame.Height.navigation
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(nibWithCellClass: ConversationCollectionCell.self)
        collectionView.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: Conversation.HeaderLoadingView.self)
        collectionView.alpha = 0
    }
    
    func loadData() {
        let limit = max(min(dataSource.count, 200), messagePageLimit)
        viewModel.loadData(limit: limit)
            .subscribe { [weak self] items in
                self?.hasEarlyMessage = items.count >= limit
                self?.dataSource = items
                self?.reloadCollectionView()
            } onError: { error in
                
            }
            .disposed(by: bag)
        
    }
    
    func loadMore() {
        viewModel.loadMore(limit: messagePageLimit, offset: dataSource.count)
            .subscribe { [weak self] items in
                guard let `self` = self else { return }

                var source = self.dataSource
                source.insert(contentsOf: items, at: 0)
                self.hasEarlyMessage = items.count == messagePageLimit
                self.dataSource = source
                self.hasTriggeredLoadEarly = false
                self.collectionView.reloadDataAndKeepOffset()

            } onError: { [weak self] _ in

            }
            .disposed(by: bag)
        
    }
    
    func bindSubviewEvent() {
        updateProfile()
        fetchRealation()
        fetchUserStatus()
        loadData()

        DMManager.shared.observableMessages(for: viewModel.targetUid)
            .subscribe(onNext: { [weak self] in
                self?.loadData()
            })
            .disposed(by: bag)
                
        bottomBar.actionHandler = { [weak self] action in
            switch action {
            case .gif:
                self?.showGifViewController()
            case .send(let text):
                self?.sendMessage(text)
                Logger.Action.log(.dm_detail_send_msg, categoryValue: "text", self?.conversation.fromUid)
            }
        }
        
        Settings.shared.amongChatUserProfile.replay()
            .skip(1)
            .subscribe(onNext: { [weak self] _ in
                self?.collectionView.reloadData()
            })
            .disposed(by: bag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self, self.bottomBar.isFirstResponder else {
                    return
                }
                cdPrint("bottomBar: \(keyboardVisibleHeight)")
                self.keyboardVisibleHeight = keyboardVisibleHeight
                self.updateContentInset()
                let bottomBarHeight = 64 + Frame.Height.safeAeraBottomHeight - (keyboardVisibleHeight > 0 ? Frame.Height.safeAeraBottomHeight : 0)
                self.bottomBar.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    maker.height.equalTo(bottomBarHeight)
                }
                let isKeyboardShow = keyboardVisibleHeight > 0
                self.collectionViewBottomConstraint.constant = collectionBottomEdge + keyboardVisibleHeight - (isKeyboardShow ? Frame.Height.safeAeraBottomHeight : 0)
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
                self.messageListScrollToBottom()
            })
            .disposed(by: bag)
        
        bottomBar.voiceButton.audioFileObservable
            .subscribe(onNext: { [weak self] (audioFileSingleValue) in
                
                guard let `self` = self else { return }
                
                audioFileSingleValue
                    .subscribe(onSuccess: { [weak self] url, seconds in
                        //TODO: url, seconds
                        self?.sendVoiceMessage(duration: seconds, filePath: url.path)
                        Logger.Action.log(.dm_detail_send_msg, categoryValue: "voice", self?.conversation.fromUid)
                    }, onError: { [weak self] (error) in
                        guard let msgError = error as? MsgError else {
                            let err = error as NSError
                            self?.view.raft.autoShow(.text(err.localizedDescription))
                            return
                        }
                        
                        guard let msg = msgError.msg else {
                            return
                        }
                        
                        switch msgError.code {
                        case -100:
                            //TODO: canceled
                            self?.view.raft.autoShow(.text(msg))
                        case -101:
                            //TODO: too short
                            self?.view.raft.autoShow(.text(msg))
                        default:
                            //其他都是retry
                            self?.view.raft.autoShow(.text(msg))
                        }
                    })
                    .disposed(by: self.bag)
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
        
        rx.viewDidAppear.take(1)
            .subscribe(onNext: { [weak self] (_) in
                Logger.Action.log(.dm_detail_imp, categoryValue: nil, self?.conversation.fromUid)
            })
            .disposed(by: bag)

    }
}


extension UICollectionView {
    public func reloadDataAndKeepOffset() {
        // stop scrolling
        setContentOffset(contentOffset, animated: false)
        
        // calculate the offset and reloadData
        let beforeContentSize = contentSize
        reloadData()
        layoutIfNeeded()
        let afterContentSize = contentSize
        
        // reset the contentOffset after data is updated
        let newOffset = CGPoint(
            x: contentOffset.x + (afterContentSize.width - beforeContentSize.width),
            y: contentOffset.y + (afterContentSize.height - beforeContentSize.height))
        setContentOffset(newOffset, animated: false)
    }
}
