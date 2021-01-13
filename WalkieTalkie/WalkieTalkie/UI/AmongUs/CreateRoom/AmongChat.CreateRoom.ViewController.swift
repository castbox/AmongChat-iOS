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
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - interSpace ) / 2
            let cellHeight = cellWidth * hwRatio
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
            return btn
        }()
        
        private lazy var bottomrBarShadowIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_home_tab_shadow())
            return i
        }()
        
        override var contentScrollView: UIScrollView? {
            topicCollectionView
        }
        
        typealias TopicViewModel = AmongChat.CreateRoom.TopicViewModel
        private lazy var topicDataSource: [TopicViewModel] = (Settings.shared.supportedTopics.value?.topicList ?? [Entity.SummaryTopic]())
            .map { TopicViewModel(with: $0) } {
            didSet {
                topicCollectionView.reloadData()
            }
        }
        
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
//        Logger.Action.log(.create_topic_create, categoryValue: name, privateStateSwitch.roomPublicType.rawValue)
    }
    
    @objc
    private func onCardBtn() {
        
        let alert = amongChatAlert(title: nil, confirmTitle: R.string.localizable.toastConfirm())
        
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
                lb.font = R.font.nunitoBold(size: 20)
                lb.textColor = UIColor.white
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
            
            v.addSubviews(views: tipLb, cardIcon, cardCountLb, msgLb)
            
            tipLb.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(31)
                maker.leading.trailing.equalToSuperview().inset(42)
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
                maker.bottom.equalToSuperview().inset(24)
            }
            
            return v
        }()
        
        alert.contentView.addSubview(content)
        content.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        alert.visualStyle.width = Frame.Screen.width - 28 * 2
        alert.visualStyle.verticalElementSpacing = 0
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
        
        Settings.shared.lastCreatedTopic.replay().filterNil()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (topic) in
                
            })
            .disposed(by: bag)
    }
    
    private func createRoom(with name: String) {
        
        view.endEditing(true)
        
        typealias Topic = AmongChat.Topic
                
        var roomProto = Entity.RoomProto()
        roomProto.state = privateStateSwitch.roomPublicType
        
        let alphabetCode = { (originString: String) -> String in
            let set = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").inverted
            let filteredString = originString.components(separatedBy: set).joined(separator: "")
            return filteredString
        }
        
        if let topic = Topic(rawValue: alphabetCode(name).lowercased()) {
            roomProto.topicId = topic.rawValue
        } else {
            roomProto.topicId = AmongChat.Topic.chilling.rawValue
        }
                
        switch roomProto.topicType {
        case .chilling:
            roomProto.note = name
            
        default:
            ()
        }
        
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        let _ = Request.createRoom(roomProto)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (room) in
                // TODO: - 创建房间成功
                guard let `self` = self else {
                    return
                }
                guard let room = room else {
                    self.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    return
                }
                self.view.endEditing(true)
                
                AmongChat.Room.ViewController.join(room: room, from: self, logSource: ParentPageSource(.create))
                
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
            })
    }
    
    private func fetchData() {
        
        let hudRemoval: (() -> Void)? = topicDataSource.count > 0 ? nil : view.raft.show(.loading, userInteractionEnabled: false)
        Request.topics()
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (s) in
                guard let summary = s else {
                    self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    return
                }
                self?.topicDataSource = summary.topicList.map({ TopicViewModel(with: $0) })
                
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.localizedDescription))
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


