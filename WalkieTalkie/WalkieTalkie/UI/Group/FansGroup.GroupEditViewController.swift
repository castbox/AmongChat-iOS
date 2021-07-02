//
//  FansGroup.GroupEditViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/8.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher
import SDCAlertView
import JXPagingView

extension FansGroup {
    
    class GroupEditViewController: WalkieTalkie.ViewController {
                
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatGroupInfo()
            return n
        }()
        
        private typealias InfoSetUpView = FansGroup.Views.GroupInfoSetUpView
        private lazy var setUpInfoView: InfoSetUpView = {
            let s = InfoSetUpView()
            s.addCoverBtn.editable = true
            s.nameView.inputField.text = groupInfo.group.name
            s.descriptionView.inputTextView.text = groupInfo.group.description
            return s
        }()
        
        private lazy var deleteView: UIView = {
            let v = UIView()
            
            let deleteBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.layer.cornerRadius = 25
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                btn.setTitle(R.string.localizable.amongChatGroupDeleteGroup(), for: .normal)
                btn.setImage(R.image.ac_group_delete(), for: .normal)
                btn.setImage(R.image.ac_group_delete()?.withRenderingMode(.alwaysTemplate), for: .disabled)
                btn.tintColor = UIColor(hex6: 0x757575)
                btn.setImageTitleHorizontalSpace(4)
                btn.setTitleColor(UIColor(hex6: 0xFB5858), for: .normal)
                btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
                btn.backgroundColor = UIColor(hex6: 0x232323)
                btn.rx.controlEvent(.primaryActionTriggered)
                    .subscribe(onNext: { [weak self] (_) in
                        self?.toDeleteGroup(completionHandler: {
                            self?.navigationController?.popViewController(animated: true)
                        })
                    })
                    .disposed(by: bag)
                return btn
            }()
            
            deleteBtn.isEnabled = groupInfo.group.status == 0
            
            v.addSubview(deleteBtn)
            deleteBtn.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(50)
                maker.top.equalTo(36)
            }
            return v
        }()
        private let deleteViewHeight: CGFloat = 130
        
        private lazy var headerView: UIView = {
            let v = UIView()
            
            v.addSubviews(views: setUpInfoView, deleteView)
            
            setUpInfoView.snp.makeConstraints { maker in
                maker.leading.top.trailing.equalToSuperview()
            }
            
            deleteView.snp.makeConstraints { maker in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.top.equalTo(setUpInfoView.snp.bottom)
                maker.height.equalTo(deleteViewHeight)
            }
            
            return v
        }()
        
        private typealias SegmentedButton = FansGroup.GroupsViewController.SegmentedButton
        private lazy var segmentedButton: SegmentedButton = {
            let s = SegmentedButton()
            let bg = UIView()
            bg.backgroundColor = UIColor(hex6: 0x121212)
            s.addSubview(bg)
            s.sendSubviewToBack(bg)
            bg.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: -Frame.Height.safeAeraTopHeight, left: 0, bottom: 0, right: 0))
            }
            s.selectedIndexObservable
                .subscribe(onNext: { [weak self] (idx) in
                    guard let `self` = self else { return }
                    let offset = CGPoint(x: self.pagingView.bounds.width * CGFloat(idx), y: 0)
                    self.pagingView.listContainerView.didClickSelectedItem(at: idx)
                    self.pagingView.listContainerView.contentScrollView().setContentOffset(offset, animated: true)
                })
                .disposed(by: bag)
            s.setButtons(tuples: [(normalIcon: nil, selectedIcon: nil, normalTitle: R.string.localizable.amongChatGroupJoined(), selectedTitle: nil),
                                  (normalIcon: nil, selectedIcon: nil, normalTitle: R.string.localizable.amongChatGroupRequests(), selectedTitle: nil)
            ])

            return s
        }()
        private let segmentedBtnHeight = CGFloat(60)
        
        private lazy var pagingView: JXPagingView = {
            let p = JXPagingView(delegate: self, listContainerType: .scrollView)
            p.backgroundColor = UIColor(hex6: 0x121212)
            p.mainTableView.backgroundColor = UIColor(hex6: 0x121212)
            p.pinSectionHeaderVerticalOffset = NavigationBar.barHeight.int + Frame.Height.safeAeraTopHeight.int
            return p
        }()
        
        private lazy var memberListVC: FansGroup.GroupMemberListViewController = {
            let vc = FansGroup.GroupMemberListViewController(with: groupInfo)
            vc.showKick = true
            return vc
        }()
        
        private lazy var requestListVC: FansGroup.GroupJoinRequestListViewController = {
            let vc = FansGroup.GroupJoinRequestListViewController(with: groupInfo.group.gid)
            vc.loadViewIfNeeded()
            return vc
        }()
        
        private lazy var dataViews: [JXPagingViewListViewDelegate] = [memberListVC, requestListVC]
        
        private var pageIndex: Int = 0 {
            didSet {
                segmentedButton.updateSelectedIndex(pageIndex)
            }
        }
        
        private var groupInfo: Entity.GroupInfo
        private var currentTopic: FansGroup.TopicViewModel
        
        init(groupInfo: Entity.GroupInfo) {
            self.groupInfo = groupInfo
            let topic = Entity.SummaryTopic(topicId: groupInfo.group.topicId, coverUrl: groupInfo.group.coverURL, bgUrl: nil, playerCount: nil, topicName: groupInfo.group.topicName)
            currentTopic = FansGroup.TopicViewModel(with: topic)
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            bindSubviewEvents()
        }
    }
    
}

extension FansGroup.GroupEditViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }
    
}

extension FansGroup.GroupEditViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: pagingView, navView)
        
        pagingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(Frame.Height.safeAeraTopHeight)
        }
        
        
        if let cover = groupInfo.group.cover.url {
            KingfisherManager.shared.retrieveImageObservable(with: cover)
                .take(1)
                .bind(to: setUpInfoView.addCoverBtn.coverRelay)
                .disposed(by: bag)
        }
        
        setUpInfoView.topicSetView.bindViewModel(currentTopic)
    }
    
    private func bindSubviewEvents() {
        
        setUpInfoView.addCoverBtn.tapHandler = { [weak self] in
            let vc = FansGroup.SelectCoverModal()
            vc.imageSelectedHandler = { image in
                self?.setUpInfoView.addCoverBtn.coverRelay.accept(image)
                self?.updateGroupCover(image)
            }
            vc.showModal(in: self)
        }
        
        setUpInfoView.topicSetView.tapHandler = { [weak self] in
            Logger.Action.log(.group_info_clk, categoryValue: self?.groupInfo.group.topicId, "add_topic")
            let vc = FansGroup.AddTopicViewController(self?.currentTopic.topic.topicId)
            vc.topicSelectedHandler = { [weak self] topic in
                self?.currentTopic = topic
                self?.setUpInfoView.topicSetView.bindViewModel(topic)
                self?.updateGroupTopic(topic.topic.topicId)
            }
            self?.presentPanModal(vc)
        }
        
        Observable.combineLatest(
            setUpInfoView.nameView.inputField.rx.text,
            setUpInfoView.nameView.isEdtingRelay
        )
        .skip(1)
        .debounce(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
        .subscribe(onNext: { [weak self] name, isEditing in
            guard !isEditing else { return }
            self?.updateGroupName(name)
        })
        .disposed(by: bag)
        
        Observable.combineLatest(
            setUpInfoView.descriptionView.inputTextView.rx.text,
            setUpInfoView.descriptionView.isEdtingRelay
        )
        .skip(1)
        .debounce(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
        .subscribe(onNext: { [weak self] desc, isEditing in
            guard !isEditing else { return }
            self?.updateGroupDescription(desc)
        })
        .disposed(by: bag)
                
        pagingView.listContainerView.contentScrollView().rx.didEndDecelerating
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                let scrollView = self.pagingView.listContainerView.contentScrollView()
                self.pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
            })
            .disposed(by: bag)
        
        requestListVC.requestsCountObservable
            .subscribe(onNext: { [weak self] (count) in
                
                let requestsTitleLabel = (self?.segmentedButton.buttonOf(1) as? UIButton)?.titleLabel
                
                guard count > 0 else {
                    requestsTitleLabel?.badgeOff()
                    return
                }
                
                requestsTitleLabel?.badgeOn(string: count.string, hAlignment: .headToTail(-0.5), topInset: 0, diameter: 16, borderWidth: 0, borderColor: nil)
                
            })
            .disposed(by: bag)
        
        Observable.combineLatest(RxKeyboard.instance.visibleHeight.asObservable(), setUpInfoView.textViewObservable)
            .subscribe(onNext: { [weak self] keyboardVisibleHeight, textingView in
                                
                guard let `self` = self else { return }
                
                guard keyboardVisibleHeight > 0 else {
                    self.pagingView.mainTableView.contentOffset = .zero
                    return
                }
                
                let rect = self.setUpInfoView.convert(textingView.frame, to: self.view)
                let distance = Frame.Screen.height - keyboardVisibleHeight - rect.maxY - 40
                
                guard distance < 0 else {
                    return
                }
                
                UIView.animate(withDuration: RxKeyboard.instance.animationDuration) {
                    self.pagingView.mainTableView.contentOffset.y = self.pagingView.mainTableView.contentOffset.y - distance
                }
            })
            .disposed(by: bag)
        
        setUpInfoView.descriptionView.isEdtingRelay
            .subscribe(onNext: { [weak self] isEditing in
                
                self?.setUpInfoView.descriptionView.inputTextView.isScrollEnabled = isEditing
                self?.pagingView.mainTableView.isScrollEnabled = !isEditing
                
            })
            .disposed(by: bag)

        
    }
    
    private func updateGroupCover(_ image: UIImage) {
        
        let hudRemoval = self.view.raft.show(.loading)
        
        FansGroup.CreateGroupViewController.ViewModel.uploadCover(coverImage: image)
            .do(onDispose: {
                hudRemoval()
            })
            .map({
                Entity.GroupProto(topicId: nil, cover: $0, name: nil, description: nil)
            })
            .subscribe(onSuccess: { [weak self] (groupProto) in
                self?.updateGroup(groupProto)
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
    }
    
    private func updateGroupName(_ name: String?) {
        updateGroup(Entity.GroupProto(topicId: nil, cover: nil, name: name, description: nil))
    }
    
    private func updateGroupDescription(_ desc: String?) {
        updateGroup(Entity.GroupProto(topicId: nil, cover: nil, name: nil, description: desc))
    }
    
    private func updateGroupTopic(_ topicId: String) {
        updateGroup(Entity.GroupProto(topicId: topicId, cover: nil, name: nil, description: nil))
    }
    
    private func updateGroup(_ groupProto: Entity.GroupProto) {
        
        guard groupProto.isValid else {
            return
        }
        
        let hudRemoval = self.view.raft.show(.loading)
        
        Request.updateGroup(groupInfo.group.gid, groupData: groupProto)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { (group) in
                FansGroup.GroupUpdateNotification.publishNotificationOf(group: group, action: .updated)
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
        
    }
    
    private func toDeleteGroup(completionHandler: @escaping (() -> Void)) {
        
        let messageAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.amongChatGroupDeleteTip(),
                                                                 attributes: [
                                                                    NSAttributedString.Key.font : R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: UIColor.white
                                                                 ])
        
        let cancelAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.toastCancel(),
                                                                attributes: [
                                                                    NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: "#6C6C6C".color()
                                                                ])
        
        let confirmAttr = NSAttributedString(string: R.string.localizable.amongChatDelete(),
                                             attributes: [
                                                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                .foregroundColor: "#FB5858".color()
                                             ])
        
        let alertVC = AlertController(attributedTitle: nil, attributedMessage: messageAttr, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alertVC.visualStyle = visualStyle
        
        alertVC.addAction(AlertAction(attributedTitle: cancelAttr, style: .normal))
        
        alertVC.addAction(AlertAction(attributedTitle: confirmAttr, style: .normal, handler: { [weak self] _ in
            Logger.Action.log(.group_info_clk, categoryValue: self?.groupInfo.group.topicId, "delete_confirm")
            guard let `self` = self else { return }
            
            let hudRemoval: (() -> Void)? = self.view.raft.show(.loading, userInteractionEnabled: false)
            
            Request.deleteGroup(self.groupInfo.group.gid)
                .do(onDispose: {
                    hudRemoval?()
                })
                .subscribe(onSuccess: { [weak self] (_) in
                    guard let `self` = self else { return }
                    FansGroup.GroupUpdateNotification.publishNotificationOf(group: self.groupInfo.group, action: .removed)
                    completionHandler()
                }, onError: { (error) in
                    
                })
                .disposed(by: self.bag)
        })
        )
        
        alertVC.view.backgroundColor = UIColor.black.alpha(0.6)
        alertVC.present()
        
    }
    
}

extension FansGroup.GroupEditViewController {
    
    class func groupEditVC(_ groupId: String) -> Single<FansGroup.GroupEditViewController> {
        return Request.groupInfo(groupId)
            .map({ return FansGroup.GroupEditViewController(groupInfo: $0) })
    }
}

extension FansGroup.GroupEditViewController: JXPagingViewDelegate {
    
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int {
        return setUpInfoView.viewHeight.int + deleteViewHeight.int
    }
    
    func tableHeaderView(in pagingView: JXPagingView) -> UIView {
        return headerView
    }
    
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        return segmentedBtnHeight.int
    }
    
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        return segmentedButton
    }
    
    func numberOfLists(in pagingView: JXPagingView) -> Int {
        return dataViews.count
    }
    
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        return dataViews[index]
    }
    
    func mainTableViewDidScroll(_ scrollView: UIScrollView) {
        let distance = scrollView.contentOffset.y
        setUpInfoView.enlargeTopGbHeight(extraHeight: -distance)
        navView.backgroundView.alpha = distance / NavigationBar.barHeight
        navView.backgroundView.isHidden = distance <= 0
    }
}
