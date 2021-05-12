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
    
    private var dataSource: [Conversation.MessageCellViewModel] = [] {
        didSet {
            reloadCollectionView()
        }
    }
    
    var followedHandle:((Bool) -> Void)?
    
//    convenience init(_ uid: String, conversation: Entity.DMConversation?) {
//        self.conversation = conversation
//        self.viewModel = Conversation.ViewModel(conversation)
//        super.init(nibName: nil, bundle: nil)
//    }
    
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
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
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
                    self.liveView.label.text = room.topicName
                    self.liveView.joinHandler = { [weak self] in
                        self?.enterRoom(roomId: room.roomId, topicId: room.topicId)
                    }
                } else if let group = status.group {
                    self.liveView.coverIV.setImage(with: group.cover)
                    self.liveView.label.text = group.name
                    self.liveView.joinHandler = { [weak self] in
                        self?.enter(group: group.gid)
                    }
                }
                self.liveView.isHidden = status.room == nil && status.group == nil
                self.updateUser(isOnline: status.isOnline == true)
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
    func updateUser(isOnline: Bool) {
        onlineView.isHidden = !isOnline
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: isOnline ? 80: 0, right: 0)
    }
    
    func fetchRealation() {
        Request.relationData(uid: viewModel.targetUid.intValue)
            .subscribe(onSuccess: { [weak self] (data) in
                guard let `self` = self, let data = data else { return }
                self.relationData = data
                self.blocked = data.isBlocked ?? false
//                self.headerView.setViewData(data, isSelf: self.isSelfProfile.value)
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
        let message = R.string.localizable.dmDeleteHistoryAlertTitle()
        let confirmString = R.string.localizable.groupRoomYes()
        showAmongAlert(title: message, message: nil,
                       cancelTitle: R.string.localizable.toastCancel(),
                       confirmTitle: confirmString, confirmAction: { [weak self] in
                        self?.deleteAllHistory()
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
        
    
    func setFollowButton(_ isFollowed: Bool) {
        if isFollowed {
            greyFollowButton()
        } else {
            yellowFollowButton()
        }
        followButton.isHidden = false
//        chatButton.isHidden = false
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
        let contentHeight = self.collectionView.contentSize.height
        let height = self.collectionView.bounds.size.height
        let contentOffsetY = self.collectionView.contentOffset.y
        let bottomOffset = contentHeight - contentOffsetY
        //            self.newMessageButton.isHidden = true
        // 消息不足一屏
        if contentHeight < height {
            self.collectionView.reloadData()
            //获取高度，更新 collectionview height
        } else {// 超过一屏
            if floor(bottomOffset) - floor(height) < 40 {// 已经在底部
                let rows = self.collectionView.numberOfItems(inSection: 0)
                let newRow = self.dataSource.count
                guard newRow > rows else { return }
                let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                collectionView.performBatchUpdates {
                    collectionView.insertItems(at: indexPaths)
                } completion: { result in
                    if let endPath = indexPaths.last {
                        self.collectionView.scrollToItem(at: endPath, at: .bottom, animated: true)
                    }
                }

//                self.collectionView.beginUpdates()
//                self.collectionView.insertRows(at: indexPaths, with: .none)
//                self.collectionView.endUpdates()
            } else {
                //                    if self.collectionView.numberOfRows(inSection: 0) <= 2 {
                //                        self.newMessageButton.isHidden = true
                //                    } else {
                //                        self.newMessageButton.isHidden = false
                //                    }
                self.collectionView.reloadData()
            }
        }
    }
    
    func showGifViewController() {
        let gifVc = Giphy.GifsViewController()
        gifVc.selectAction = { [weak self] media in
            self?.viewModel.sendGif(media)
        }
        presentPanModal(gifVc)
    }
    
    func configureSubview() {
        
        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)

        view.addSubviews(views: bottomBar, liveView)
        
        bottomBar.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(Frame.Height.safeAeraBottomHeight + 60)
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
            .subscribe(onNext: { [weak self] source in
                self?.dataSource = source
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
                self.bottomBar.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    maker.height.equalTo(keyboardVisibleHeight > 20 ? 0 : Frame.Height.safeAeraBottomHeight + 60)
                }
                self.collectionViewBottomConstraint.constant = 60 + keyboardVisibleHeight
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
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
