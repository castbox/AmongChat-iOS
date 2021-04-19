//
//  AmongChat.CreateRoom.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/13.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDCAlertView

extension AmongChat.CreateRoom {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private typealias TopicCell = AmongChat.CreateRoom.TopicCell
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatCreateRoomTitle()
            return lb
        }()
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var topicCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let vInset: CGFloat = 24
            let hwRatio: CGFloat = 128.0 / 128.0
            let interSpace: CGFloat = 20
            var columns: Int = 2
            adaptToIPad {
                columns = 4
            }
            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interSpace * CGFloat(columns - 1) ) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = ceil(cellWidth * hwRatio)
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = interSpace
            layout.sectionInset = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(TopicCell.self, forCellWithReuseIdentifier: NSStringFromClass(TopicCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()

        private lazy var confirmButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.setTitle(R.string.localizable.amongChatCreateRoomConfirmBtn(""), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var privateStateLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatCreateRoomPrivate()
            return lb
        }()
        
        private lazy var privateStateSwitch: UISwitch = {
            let sw = UISwitch()
            sw.isOn = false
            sw.onTintColor = UIColor(hexString: "#FFF000")
            sw.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.3)
            sw.layer.cornerRadius = sw.bounds.height / 2
            sw.layer.borderWidth = 0
            sw.layer.borderColor = UIColor.clear.cgColor
            return sw
        }()
        
        private lazy var bottomBar: UIView = {
            let v = UIView()
            v.backgroundColor = Theme.mainBgColor
            v.addSubviews(views: privateStateLabel, privateStateSwitch, cardButton, confirmButton)
            
            privateStateLabel.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(20)
                maker.top.equalToSuperview().offset(12.5)
            }
            
            privateStateSwitch.snp.makeConstraints { (maker) in
                maker.leading.equalTo(privateStateLabel.snp.trailing).offset(12)
                maker.centerY.equalTo(privateStateLabel)
            }
            
            cardButton.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().offset(-20)
                maker.centerY.equalTo(privateStateLabel)
            }
            
            confirmButton.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(48)
                maker.top.equalTo(62)
            }
            
            return v
        }()
        
        private lazy var cardButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onCardBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_room_card(), for: .normal)
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            return btn
        }()
        
        private lazy var bottomrBarShadowIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_create_room_bar_top_shadow())
            return i
        }()
        
        override var contentScrollView: UIScrollView? {
            topicCollectionView
        }
        
        typealias TopicViewModel = AmongChat.CreateRoom.TopicViewModel
        private lazy var topicDataSource: [TopicViewModel] = [Entity.SummaryTopic]()
            .map { TopicViewModel(with: $0) } {
            didSet {
                topicCollectionView.reloadData()
            }
        }
        
        private var selectedTopic: TopicViewModel? {
            
            guard let selectedIdx = topicCollectionView.indexPathsForSelectedItems?.first?.item,
                  let topic = topicDataSource.safe(selectedIdx) else {
                return nil
            }
            
            return topic
        }
        
        private var cardDataRelay = BehaviorRelay<Entity.AccountMetaData?>(value: nil)
        
        // MARK: -
                
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvents()
            fetchData()
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            view.endEditing(true)
        }
    }
    
}

extension AmongChat.CreateRoom.ViewController {
    
    // MARK: - UI action
    
    @objc
    private func onBackBtn() {
        navigationController?.popViewController()
    }
        
    @objc
    private func onConfirmBtn() {
        
        guard let topic = selectedTopic else {
            HapticFeedback.Impact.error()
            return
        }
        
        guard !Settings.shared.isProValue.value else {
            createRoom(with: topic, freeCard: true)
            return
        }
        
        guard let card = cardDataRelay.value,
              card.freeRoomCards > 0 else {
            showAdAlert(topic: topic)
            return
        }
        
        Logger.Action.log(.create_topic_create, categoryValue: topic.topic.topicId, privateStateSwitch.roomPublicType.rawValue)
        
        let alert = amongChatAlert(cancelTitle: R.string.localizable.toastCancel(),
                                   confirmTitle: R.string.localizable.amongChatCreateRoomCreate(),
                                   cancelAction: {
                                    Logger.Action.log(.space_card_use_dialog_clk, categoryValue: "cancel")
                                   }) { [weak self] in
            Logger.Action.log(.space_card_use_dialog_clk, categoryValue: "create")
            self?.createRoom(with: topic, freeCard: true)
        }
        
        let content: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            
            let tipLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoExtraBold(size: 16)
                lb.textColor = UIColor.white
                lb.text = R.string.localizable.amongChatCreateRoomCardConsumeContent()
                lb.textAlignment = .center
                lb.adjustsFontSizeToFitWidth = true
                return lb
            }()
            
            let cardIcon = UIImageView(image: R.image.ac_room_card2())
            
            v.addSubviews(views: tipLb, cardIcon)
            
            cardIcon.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(20)
            }
            
            tipLb.snp.makeConstraints { (maker) in
                maker.top.equalTo(cardIcon.snp.bottom).offset(12)
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.bottom.equalToSuperview().inset(24)
            }
            
            return v
        }()
        
        alert.contentView.addSubview(content)
        content.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        decorateAlert(alert)
        alert.present()
        Logger.Action.log(.space_card_use_dialog_imp)
    }
    
    @objc
    private func onCardBtn() {
        
        Logger.Action.log(.space_card_tip_clk)
        
        let alert = amongChatAlert(confirmTitle: R.string.localizable.toastConfirm())
        
        let content: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            
            let tipLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoExtraBold(size: 20)
                lb.textColor = UIColor.white
                lb.text = R.string.localizable.amongChatCreateRoomCardTipTitle()
                lb.textAlignment = .center
                lb.adjustsFontSizeToFitWidth = true
                return lb
            }()
            
            let cardIcon = UIImageView(image: R.image.ac_room_card())
            
            let cardCountLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoExtraBold(size: 20)
                lb.textColor = UIColor.white
                lb.text = "x\(cardDataRelay.value?.freeRoomCards ?? 0)"
                return lb
            }()
            
            let msgLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoBold(size: 14)
                lb.textColor = UIColor(hex6: 0xABABAB)
                lb.text = R.string.localizable.amongChatCreateRoomCardTipContent()
                lb.textAlignment = .center
                lb.numberOfLines = 0
                return lb
            }()
            
            let proLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoBold(size: 14)
                lb.textColor = UIColor(hex6: 0xABABAB)
                lb.text = R.string.localizable.amongChatCreateRoomCardUnlockPro()
                lb.textAlignment = .center
                lb.numberOfLines = 0
                return lb
            }()
            
            v.addSubviews(views: tipLb, cardIcon, cardCountLb, msgLb, proLb)
            
            tipLb.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(31)
                maker.leading.trailing.equalToSuperview().inset(20)
            }
            
            let cardLayout = UILayoutGuide()
            v.addLayoutGuide(cardLayout)
            
            cardLayout.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(tipLb.snp.bottom).offset(8)
            }
            
            cardIcon.snp.makeConstraints { (maker) in
                maker.top.leading.bottom.equalTo(cardLayout)
            }
            
            cardCountLb.snp.makeConstraints { (maker) in
                maker.centerY.trailing.equalTo(cardLayout)
                maker.leading.equalTo(cardIcon.snp.trailing).offset(11)
            }
            
            msgLb.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(cardLayout.snp.bottom).offset(12)
            }
            
            proLb.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(msgLb.snp.bottom).offset(8)
                maker.bottom.equalToSuperview().inset(28)
            }
            
            return v
        }()
        
        alert.contentView.addSubview(content)
        content.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        decorateAlert(alert)
        alert.present()
    }
}

extension AmongChat.CreateRoom.ViewController {
    
    private func setupLayout() {
        
        view.addSubviews(views: backBtn, titleLabel, topicCollectionView, bottomBar, bottomrBarShadowIV)
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
        
        topicCollectionView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(navLayoutGuide.snp.bottom)
            maker.bottom.equalTo(bottomBar.snp.top)
        }
        
        bottomBar.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(143)
        }
        
        bottomrBarShadowIV.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomBar.snp.top)
        }
    }
    
    private func setupEvents() {
        
        privateStateSwitch.rx.isOn
            .subscribe(onNext: { [weak self] (_) in
                
                self?.confirmButton.setTitle(R.string.localizable.amongChatCreateRoomConfirmBtn(self?.privateStateSwitch.roomPublicType.string ?? ""), for: .normal)
                
            })
            .disposed(by: bag)
        
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { (_) in
                Logger.Action.log(.create_topic_imp, category: nil)
            })
            .disposed(by: bag)
        
        Observable.combineLatest(Settings.shared.lastCreatedTopic.replay().take(1),
                                 Settings.shared.supportedTopics.replay())
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] topic, summary in
                
                guard let `self` = self,
                      var supportedTopics = summary?.topicList,
                      supportedTopics.count > 0 else {
                    return
                }
                
                if let topic = topic,
                   let lastTopic = supportedTopics.removeFirst(where: { $0.topicId == topic.topicId }) {
                    supportedTopics.insert(lastTopic, at: 0)
                }
                
                self.topicDataSource = supportedTopics.map({ TopicViewModel(with: $0) })
                
                self.topicCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .top)
                self.topicCollectionView.contentOffset = .zero
            })
            .disposed(by: bag)
        
        Observable.combineLatest(cardDataRelay, Settings.shared.isProValue.replay())
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data, isPro in
                
                guard !isPro else {
                    self?.cardButton.setTitle(R.string.localizable.amongChatCreateRoomCardUnlimited(), for: .normal)
                    return
                }
                
                self?.cardButton.setTitle("x\(data?.freeRoomCards ?? 0)", for: .normal)
            })
            .disposed(by: bag)
    }
    
    private func createRoom(with topic: TopicViewModel, freeCard: Bool? = nil) {
        //dismiss
        UIApplication.tabBarController?.dismissNotificationBanner()

        var roomProto = topic.roomProto
        roomProto.state = privateStateSwitch.roomPublicType
        if let freeCard = freeCard {
            roomProto.entry = freeCard ? Entity.RoomProto.cardEntry : Entity.RoomProto.watchAdEntry
        }
        
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        
        let loadingCompletion = { [weak self] in
            hudRemoval()
            self?.bottomBar.isUserInteractionEnabled = true
            self?.topicCollectionView.isUserInteractionEnabled = true
        }
        
        bottomBar.isUserInteractionEnabled = false
        topicCollectionView.isUserInteractionEnabled = false
        
        let _ = Request.createRoom(roomProto)
            .do(onDispose: {
                loadingCompletion()
            })
            .subscribe(onSuccess: { [weak self] (room) in
                guard let `self` = self else {
                    return
                }
                guard let room = room else {
                    self.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    return
                }
                
                AmongChat.Room.ContainerController.join(room: room, from: self, logSource: ParentPageSource(.create))
                Settings.shared.lastCreatedTopic.value = topic.topic
            }, onError: { [weak self] (error) in
                
                guard let msgError = error as? MsgError, let code = msgError.codeType else {
                    self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    return
                }
                switch code {
                case .notEnoughRoomCard:
                    if Settings.shared.isProValue.value {
                        //vip 状态已失效
                        Settings.shared.updateProfile()
                    }
                    self?.showAdAlert(topic: topic)
                case .needUpgrade:
                    self?.view.raft.autoShow(.text(R.string.localizable.forceUpgradeTip()))
                default:
                    self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                }
                
            })
    }
    
    private func fetchData() {
        
        let hudRemoval: (() -> Void)? = Settings.shared.supportedTopics.value?.topicList.count ?? 0 > 0 ? nil : view.raft.show(.loading, userInteractionEnabled: false)
        Request.topics()
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (s) in
                guard let summary = s else {
                    self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    return
                }
                Settings.shared.supportedTopics.value = summary
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.localizedDescription))
            })
            .disposed(by: bag)
        
        Request.accountMetaData()
            .subscribe(onSuccess: { [weak self] (data) in
                guard let data = data else { return }
                self?.cardDataRelay.accept(data)
            })
            .disposed(by: bag)
    }
    
    private func decorateAlert(_ alert: AlertController) {
        var hPadding: CGFloat = 28
        adaptToIPad {
            hPadding = 190
        }
        alert.visualStyle.width = Frame.Screen.width - hPadding * 2
        alert.visualStyle.verticalElementSpacing = 0
        alert.visualStyle.contentPadding = UIEdgeInsets(top: 33.5, left: 0, bottom: 0, right: 0)
        alert.visualStyle.actionViewSize = CGSize(width: 0, height: 49)
        alert.view.backgroundColor = UIColor.black.alpha(0.6)
    }
    
    private func showAdAlert(topic: TopicViewModel) {
        
        let alertVC = AlertController(title: nil, message: nil, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alertVC.visualStyle = visualStyle
        
        let content: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            
            let tipLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoExtraBold(size: 20)
                lb.textColor = UIColor.white
                lb.text = R.string.localizable.amongChatCreateRoomCardInsufficientTitle()
                lb.textAlignment = .center
                lb.adjustsFontSizeToFitWidth = true
                return lb
            }()
            
            let msgLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoBold(size: 14)
                lb.textColor = UIColor(hex6: 0xABABAB)
                lb.text = R.string.localizable.amongChatCreateRoomCardInsufficientContent()
                lb.textAlignment = .center
                lb.numberOfLines = 0
                return lb
            }()
            
            let proLb: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoBold(size: 14)
                lb.textColor = UIColor(hex6: 0xABABAB)
                lb.text = R.string.localizable.amongChatCreateRoomCardUnlockPro()
                lb.textAlignment = .center
                lb.numberOfLines = 0
                return lb
            }()
            
            let proBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.layer.cornerRadius = 24
                btn.backgroundColor = UIColor(hexString: "#FFF000")
                btn.setTitle(R.string.localizable.profileUnlockPro(), for: .normal)
                btn.setTitleColor(.black, for: .normal)
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                return btn
            }()
            
            let claimBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.layer.cornerRadius = 24
                btn.backgroundColor = UIColor(hexString: "#FFF000")
                btn.setTitle(R.string.localizable.amongChatCreateRoomCardClaim() + " x1", for: .normal)
                btn.setTitleColor(.black, for: .normal)
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                btn.setImage(R.image.ac_channel_card_ad(), for: .normal)
                btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
                btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
                return btn
            }()
            
            let cancelBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.backgroundColor = .clear
                btn.setTitle(R.string.localizable.toastCancel(), for: .normal)
                btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                return btn
            }()
            
            proBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak alertVC, weak self] (_) in
                    alertVC?.dismiss(animated: true, completion: {
                        self?.presentPremiumView(source: .room_create)
                    })
                    Logger.Action.log(.space_card_pro_clk)
                }).disposed(by: bag)
            
            claimBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak alertVC, weak self] (_) in
                    alertVC?.dismiss(animated: true, completion: {
                        self?.requestAppTrackPermission(completion: {
                            self?.showAd(topic: topic)
                        })
                    })
                    Logger.Action.log(.space_card_ads_claim_clk)
                }).disposed(by: bag)
            
            cancelBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak alertVC] (_) in
                    alertVC?.dismiss()
                })
                .disposed(by: bag)
            
            v.addSubviews(views: tipLb, msgLb, proLb, proBtn, claimBtn, cancelBtn)
            
            tipLb.snp.makeConstraints { (maker) in
                maker.top.equalTo(20)
                maker.leading.trailing.equalToSuperview().inset(20)
            }
            
            msgLb.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(tipLb.snp.bottom).offset(12)
            }
            
            proLb.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(msgLb.snp.bottom).offset(8)
            }
            
            proBtn.snp.makeConstraints { (maker) in
                maker.height.equalTo(48)
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(proLb.snp.bottom).offset(28)
            }
            
            claimBtn.snp.makeConstraints { (maker) in
                maker.height.equalTo(48)
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(proBtn.snp.bottom).offset(12)
            }
            
            cancelBtn.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(claimBtn.snp.bottom).offset(12)
                maker.bottom.equalToSuperview().inset(16)
            }
            
            return v
        }()

        alertVC.contentView.addSubview(content)
        content.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        decorateAlert(alertVC)
        alertVC.present()
        Logger.Action.log(.space_card_ads_dialog_imp)
    }
    
    private func showAd(topic: TopicViewModel) {
        
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        
        let loadingCompletion = { [weak self] in
            hudRemoval()
            self?.bottomBar.isUserInteractionEnabled = true
            self?.topicCollectionView.isUserInteractionEnabled = true
        }
        
        bottomBar.isUserInteractionEnabled = false
        topicCollectionView.isUserInteractionEnabled = false
        AdsManager.shared.earnARewardOfVideo(fromVC: self, adPosition: .channelCard)
            .take(1)
            .asSingle()
            .subscribe(onSuccess: { (_) in
                loadingCompletion()
                Logger.Action.log(.space_card_ads_claim_success)
                self.createRoom(with: topic, freeCard: false)
            }, onError: { [weak self] (error) in
                loadingCompletion()
                self?.view.raft.autoShow(.text(error.localizedDescription))
                Logger.Action.log(.space_card_ads_claim_failed)
                self?.createRoom(with: topic, freeCard: false)
            })
            .disposed(by: bag)
    }
}

extension AmongChat.CreateRoom.ViewController: UICollectionViewDataSource {

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topicDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TopicCell.self), for: indexPath) as! TopicCell
        if let topic = topicDataSource.safe(indexPath.item) {
            cell.bindViewModel(topic)
        }
        return cell
    }
    
}

extension AmongChat.CreateRoom.ViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
}

fileprivate extension UISwitch {
    
    var roomPublicType: Entity.RoomPublicType {
        
        return isOn ? .private : .public
        
    }
    
}

fileprivate extension Entity.RoomPublicType {
    var string: String {
        switch self {
        case .private:
            return R.string.localizable.roomPrivate().lowercased()
        case .public:
            return R.string.localizable.roomPublic().lowercased()
        }
    }
}

extension AmongChat.CreateRoom.ViewController {
    
    private func amongChatAlert(cancelTitle: String? = nil, confirmTitle: String? = nil, cancelAction: (() -> Void)? = nil, confirmAction: (() -> Void)? = nil) -> AlertController {
        
        var cancelAttr: NSAttributedString? = nil
        if let cancel = cancelTitle {
            cancelAttr = NSAttributedString(string: cancel,
                                            attributes: [
                                                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                .foregroundColor: "#6C6C6C".color()
                                            ])
        }
        
        var confirmAttr: NSAttributedString? = nil
        if let confirm = confirmTitle {
            confirmAttr = NSAttributedString(string: confirm,
                                             attributes: [
                                                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                .foregroundColor: "#FFF000".color()
                                             ])
        }
        
        let alertVC = AlertController(attributedTitle: nil, attributedMessage: nil, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alertVC.visualStyle = visualStyle
        
        if let c = cancelAttr {
            alertVC.addAction(AlertAction(attributedTitle: c, style: .normal, handler: { _ in
                cancelAction?()
            }))
        }
        
        if let c = confirmAttr {
            alertVC.addAction(AlertAction(attributedTitle: c, style: .normal) { _ in
                confirmAction?()
            })
        }
        
        return alertVC
    }
    
}
