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

private let bottomBarHeight = 64 + Frame.Height.safeAeraBottomHeight

class ConversationViewController: ViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userInfostackView: UIStackView!
    @IBOutlet weak var onlineView: UIView!
    
    private(set) lazy var liveView: Social.ProfileViewController.LiveCell = {
        let o = Social.ProfileViewController.LiveCell()
        o.isHidden = true
        return o
    }()
    
    private lazy var bottomBar = ConversationBottomBar()
    
    private var conversation: Entity.DMConversation
    
    private let viewModel: Conversation.ViewModel
    
    private var relationData: Entity.RelationData?
    private var blocked = false
    private var firstDataLoaded: Bool = true
    //count changed
    private var lastCount: Int = 0
    private var isFirstShowFollow: Bool = true
    private var keyboardVisibleHeight: CGFloat = 0
//    private var isKeyboardShow = false
    
    private var dataSource: [Conversation.MessageCellViewModel] = [] {
        didSet {
            reloadCollectionView()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
    }
    
    override func showReportSheet() {
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
        //        IMManager.shared.sendFile()
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
        //        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        cell.bind(item)
        cell.actionHandler = { [weak self] action in
            switch action {
            case .resend(let message):
                self?.viewModel.sendMessage(message)
            case .clickVoiceMessage(let message):
                self?.viewModel.clearUnread(message)
            case .user(let uid):
                let vc = Social.ProfileViewController(with: uid.string.intValue)
                self?.navigationController?.pushViewController(vc)
            }
        }
        return cell
    }
}

extension ConversationViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let viewModel = dataSource.safe(indexPath.item) else {
            return .zero
        }
        
        return CGSize(width: Frame.Screen.width, height: viewModel.height)
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
                    self.liveView.joinHandler = { [weak self] in
                        self?.enterRoom(roomId: room.roomId, topicId: room.topicId)
                    }
                } else if let group = status.group {
                    self.liveView.coverIV.setImage(with: group.cover)
                    self.liveView.label.text = R.string.localizable.profileUserInGroup(group.name)
                    self.liveView.joinHandler = { [weak self] in
                        self?.enter(group: group.gid)
                    }
                }
                self.liveView.isHidden = status.room == nil && status.group == nil
                self.updateUser(isOnline: status.isOnline == true && self.liveView.isHidden)
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
        updateContentInsert()
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
            //            Logger.Action.log(.profile_other_clk, category: .unfollow, "\(uid)")
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
            //            Logger.Action.log(.profile_other_clk, category: .follow, "\(uid)")
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
}


private extension ConversationViewController {
    
    func deleteAllHistory() {
        let removeBlock = view.raft.show(.loading)
        viewModel.deleteAllHistory()
            .subscribe(onSuccess: { [weak self] in
                removeBlock()
                self?.navigationController?.popViewController()
            }) { error in
                removeBlock()
            }
            .disposed(by: bag)
    }
    func sendVoiceMessage(duration: Int, filePath: String) {
        //        let removeBlock = view.raft.show(.loading)
        viewModel.sendVoiceMessage(duration: duration, filePath: filePath)
            .subscribe(onSuccess: { result in
                //                removeBlock()
            }) { error in
                //                removeBlock()
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
            case .block, .unblock:
                self?.showBlockAlter()
            case .dmDeleteHistory:
                self?.showDeleteHistoryAlter()
            default:
                break
            }
        }
    }
    
    func showDeleteHistoryAlter() {
        
        let titleAttr = NSAttributedString(string: R.string.localizable.dmDeleteHistoryAlertTitle(), attributes: [
            NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16),
            .foregroundColor: UIColor.white
        ])
        
        let cancelAttr = NSAttributedString(string: R.string.localizable.toastCancel(), attributes: [
            NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16),
            .foregroundColor: "#6C6C6C".color()
        ])
        let confirmAttr = NSAttributedString(string: R.string.localizable.groupRoomYes(), attributes: [
            NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16),
            .foregroundColor: "#FB5858".color()
        ])
        
        let alertVC = AlertController(attributedTitle: titleAttr, attributedMessage: nil, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alertVC.visualStyle = visualStyle
        
        alertVC.addAction(AlertAction(attributedTitle: cancelAttr, style: .normal, handler: { _ in
            //                    cancelAction?()
        }))
        alertVC.addAction(AlertAction(attributedTitle: confirmAttr, style: .normal) { [weak self] _ in
            self?.deleteAllHistory()
        })
        alertVC.view.backgroundColor = UIColor.black.alpha(0.7)
        alertVC.present()
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
    
    
    func setFollowButton(_ isFollowed: Bool) {
        if isFollowed {
            greyFollowButton()
        } else {
            yellowFollowButton()
        }
        followButton.isEnabled = !isFollowed
        followButton.isHidden = isFirstShowFollow && isFollowed
        isFirstShowFollow = false
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
        let contentHeight = collectionView.contentSize.height
        let height = collectionView.bounds.size.height
        let contentOffsetY = collectionView.contentOffset.y
        let bottomOffset = contentHeight - contentOffsetY
        //            self.newMessageButton.isHidden = true
        // 消息不足一屏
        if contentHeight < height {
            if (!dataSource.isEmpty && firstDataLoaded) || keyboardVisibleHeight > 0 {
                firstDataLoaded = false
                UIView.animate(withDuration: 0) {
                    self.collectionView.reloadData()
                } completion: { _ in
                    self.messageListScrollToBottom(animated: self.keyboardVisibleHeight > 0)
                }
            } else {
                collectionView.reloadData()
                
            }
            //获取高度，更新 collectionview height
        } else {// 超过一屏
            if dataSource.count > lastCount,
               floor(bottomOffset) - floor(height) < 40 {// 已经在底部
                let rows = collectionView.numberOfItems(inSection: 0)
                let newRow = dataSource.count
                guard newRow > rows else { return }
                let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                collectionView.performBatchUpdates {
                    self.collectionView.insertItems(at: indexPaths)
                } completion: { result in
                    if let endPath = indexPaths.last {
                        self.collectionView.scrollToItem(at: endPath, at: .bottom, animated: true)
                    }
                }
            } else {
                collectionView.reloadData()
            }
        }
        lastCount = dataSource.count
    }
    
    func showGifViewController() {
        let gifVc = Giphy.GifsViewController()
        gifVc.selectAction = { [weak self] media in
            self?.viewModel.sendGif(media)
        }
        presentPanModal(gifVc)
    }
    
    func updateContentInsert() {
        //        guard collectionView.contentInset.top > 0 else {
        //            return
        //        }
        let contentHeight = dataSource.reduce(0) { $0 + $1.height }
        //top insert
        let onlineViewContentHeight: CGFloat = onlineView.isHidden ? 0 : 80
        var topInset = Frame.Screen.height - bottomBarHeight - Frame.Height.navigation - contentHeight + onlineViewContentHeight - keyboardVisibleHeight
        if topInset < 0 {
            topInset = 0
        }
        collectionView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    func messageListScrollToBottom(animated: Bool = true) {
        let rows = collectionView.numberOfItems(inSection: 0)
        if rows > 0 {
            let endPath = IndexPath(row: rows - 1, section: 0)
            //
            let contentSize = collectionView.contentSize.height
            collectionView.scrollToItem(at: endPath, at: .bottom, animated: animated)
//            collectionView.setContentOffset(CGPoint(x: 0, y: -contentSize), animated: animated)
        }
    }
    
    func configureSubview() {
        
        //        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        view.addSubviews(views: bottomBar, liveView)
        
        bottomBar.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(bottomBarHeight)
        }
        
        liveView.snp.makeConstraints { (maker) in
            maker.top.equalTo(Frame.Height.navigation + 12)
            maker.centerX.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-20)
            maker.height.equalTo(56)
        }
        
        titleLabel.text = conversation.message.fromUser.name
        collectionView.register(nibWithCellClass: ConversationCollectionCell.self)
    }
    
    func bindSubviewEvent() {
        fetchRealation()
        fetchUserStatus()
        
        viewModel.dataSourceReplay
            .skip(0)
            .subscribe(onNext: { [weak self] source in
                self?.dataSource = source
                self?.updateContentInsert()
            })
            .disposed(by: bag)
        
        bottomBar.actionHandler = { [weak self] action in
            switch action {
            case .gif:
                self?.showGifViewController()
            case .send(let text):
                self?.viewModel.sendMessage(text)
            }
        }
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self, self.bottomBar.isFirstResponder else {
                    return
                }
                self.keyboardVisibleHeight = keyboardVisibleHeight
                self.updateContentInsert()
                self.bottomBar.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    //                    maker.height.equalTo((keyboardVisibleHeight > 20 ? 0 : Frame.Height.safeAeraBottomHeight) + 60)
                }
                self.collectionViewBottomConstraint.constant = 64 + keyboardVisibleHeight
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
        
    }
}
