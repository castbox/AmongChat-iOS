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
            return s
        }()
        
        private lazy var deleteView: UIView = {
            let v = UIView()
            
            let deleteBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.layer.cornerRadius = 25
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                btn.setTitle(R.string.localizable.amongChatGroupLeaveGroup(), for: .normal)
                btn.setImage(R.image.ac_group_delete(), for: .normal)
                btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
                btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
                btn.setTitleColor(UIColor(hex6: 0xFB5858), for: .normal)
                btn.backgroundColor = UIColor(hex6: 0x232323)
                btn.rx.controlEvent(.primaryActionTriggered)
                    .subscribe(onNext: { [weak self] (_) in
                        self?.toDeleteGroup(completionHandler: {
                            self?.navigationController?.popToRootViewController(animated: true)
                        })
                    })
                    .disposed(by: bag)
                return btn
            }()
            
            v.addSubview(deleteBtn)
            deleteBtn.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(50)
                maker.top.equalTo(36)
                maker.bottom.equalTo(-44)
            }
            return v
        }()
        
        private typealias SegmentedButton = FansGroup.GroupsViewController.SegmentedButton
        private lazy var segmentedButton: SegmentedButton = {
            let s = SegmentedButton()
            s.selectedIndexObservable
                .subscribe(onNext: { [weak self] (idx) in
                    guard let `self` = self else { return }
                    let offset = CGPoint(x: self.listScrollView.bounds.width * CGFloat(idx), y: 0)
                    self.listScrollView.setContentOffset(offset, animated: true)
                })
                .disposed(by: bag)
            s.setTitles(titles: [R.string.localizable.amongChatGroupJoined(), R.string.localizable.amongChatGroupRequests()])
            return s
        }()
        
        private lazy var listScrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            s.isPagingEnabled = true
            s.delegate = self
            return s
        }()
        
        private var pageIndex: Int = 0 {
            didSet {
                segmentedButton.updateSelectedIndex(pageIndex)
            }
        }
        
        private var groupInfo: Entity.GroupInfo
        private var currentTopic: FansGroup.TopicViewModel
        
        init(groupInfo: Entity.GroupInfo) {
            self.groupInfo = groupInfo
            let topic = Entity.SummaryTopic(topicId: groupInfo.group.topicId, coverUrl: groupInfo.group.coverUrl, bgUrl: nil, playerCount: nil, topicName: groupInfo.group.topicName)
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
        
        view.addSubviews(views: setUpInfoView, navView)
        
        setUpInfoView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        setUpInfoView.appendViewContainer.addSubviews(views: deleteView, listScrollView)
        
        deleteView.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
        }
        
        listScrollView.snp.makeConstraints { (maker) in
            maker.top.equalTo(deleteView.snp.bottom).offset(104)
            maker.leading.trailing.bottom.equalToSuperview()
            maker.width.equalTo(view.snp.width).multipliedBy(2)
            maker.height.equalTo(view.snp.height)
        }
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        setUpInfoView.nameView.inputField.text = groupInfo.group.name
        setUpInfoView.descriptionView.inputTextView.text = groupInfo.group.description
        
        if let cover = groupInfo.group.cover?.url {
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
        
        setUpInfoView.layoutScrollView.rx.contentOffset
            .subscribe(onNext: { [weak self] (point) in
                
                guard let `self` = self else { return }
                
                let distance = point.y
                
                self.navView.snp.updateConstraints { (maker) in
                    maker.top.equalTo(self.topLayoutGuide.snp.bottom).offset(min(0, -distance / 3))
                }
                
                self.navView.alpha = 1 - distance / 49
            })
            .disposed(by: bag)
        
    }
    
    private func updateGroupCover(_ image: UIImage) {
        
        FansGroup.CreateGroupViewController.ViewModel.uploadCover(coverImage: image)
            .flatMap { [weak self] (coverUrl) -> Single<Void> in
                guard let `self` = self else {
                    return Single.error(MsgError.default)
                }
                let groupProto = Entity.GroupProto(topicId: nil, cover: coverUrl, name: nil, description: nil)
                return Request.updateGroup(self.groupInfo.group.gid, groupData: groupProto).map { _ in }
            }
            .subscribe(onSuccess: { (_) in
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
    private func updateGroupName(_ name: String?) {
        
        guard let name = name else { return }
        
        let groupProto = Entity.GroupProto(topicId: nil, cover: nil, name: name, description: nil)
        Request.updateGroup(groupInfo.group.gid, groupData: groupProto)
            .subscribe(onSuccess: { (_) in
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
    private func updateGroupDescription(_ desc: String?) {
        
        guard let desc = desc else { return }
        
        let groupProto = Entity.GroupProto(topicId: nil, cover: nil, name: nil, description: desc)
        Request.updateGroup(groupInfo.group.gid, groupData: groupProto)
            .subscribe(onSuccess: { (_) in
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
    private func updateGroupTopic(_ topicId: String) {
        
        let groupProto = Entity.GroupProto(topicId: topicId, cover: nil, name: nil, description: nil)
        Request.updateGroup(groupInfo.group.gid, groupData: groupProto)
            .subscribe(onSuccess: { (_) in
                
            }, onError: { (error) in
                
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
            guard let `self` = self else { return }
            
            let hudRemoval: (() -> Void)? = self.view.raft.show(.loading, userInteractionEnabled: false)
            
            Request.deleteGroup(self.groupInfo.group.gid)
                .do(onDispose: {
                    hudRemoval?()
                })
                .subscribe(onSuccess: { (_) in
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
