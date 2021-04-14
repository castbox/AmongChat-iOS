//
//  AmongGroupTopView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import EasyTipView
import RxSwift
import RxCocoa

class AmongGroupTopView: XibLoadableView {
    enum Action {
        case groupInfo
        case memberList
        case leave
        case topic
        case setupCode
        case setupLink
        case setupNotes
    }
    
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var groupCountLabel: UILabel!
    
    @IBOutlet weak var leaveButton: BottomTitleButton!
    
    @IBOutlet weak var topicIcon: UIImageView!
    @IBOutlet weak var topicNameLabel: UILabel!
    
    @IBOutlet weak var configView: AmongGroupTopicConfigView!
    
    @IBOutlet weak var onlineUserStackView: UIStackView!
    //
    @IBOutlet weak var firstUserIcon: UIImageView!
    @IBOutlet weak var secondUserIcon: UIImageView!
    @IBOutlet weak var thirdUserIcon: UIImageView!
    @IBOutlet weak var userCountLabel: UILabel!
    @IBOutlet weak var topicContainer: UIView!
    
    private lazy var topicContainerBg = FansGroup.Views.LeftEclipseView()
    private lazy var backgroundLayer = CAGradientLayer()
    var actionHandler: ((Action) -> Void)?
//    var changePublicStateHandler: CallBack?
    var leaveHandler: CallBack?
    var kickOffHandler: CallBack?
    var reportHandler: CallBack?
    var isIndicatorAnimate: Bool = false {
        didSet {
            if isIndicatorAnimate {
//                indicatorView.startAnimating()
            } else {
//                indicatorView.stopAnimating()
            }
        }
    }

//    var nextRoomHandler: CallBack?
    
    var updateEditTypeHandler: ((RoomEditType) -> Void)?
    var openGameHandler: CallBack?
    
    var group: Entity.Group {
        didSet {
            updateSubview()
        }
    }
    
    var listenerList: [Entity.UserProfile] = [] {
        didSet {
            onlineUserStackView.isHidden = listenerList.isEmpty
            if let firstUser = listenerList.safe(0) {
                firstUserIcon.isHidden = false
                onlineUserStackView.insertArrangedSubview(firstUserIcon, at: 0)
                firstUserIcon.setAvatarImage(with: firstUser.pictureUrl)
            } else {
                firstUserIcon.isHidden = true
                onlineUserStackView.removeArrangedSubview(firstUserIcon)
            }
            
            if let user = listenerList.safe(1) {
                secondUserIcon.isHidden = false
                onlineUserStackView.insertArrangedSubview(secondUserIcon, at: 1)
                secondUserIcon.setAvatarImage(with: user.pictureUrl)
            } else {
                secondUserIcon.isHidden = true
                onlineUserStackView.removeArrangedSubview(secondUserIcon)
            }
            
            if let user = listenerList.safe(2) {
                thirdUserIcon.isHidden = false
                onlineUserStackView.insertArrangedSubview(thirdUserIcon, at: 2)
                thirdUserIcon.setAvatarImage(with: user.pictureUrl)
            } else {
                thirdUserIcon.isHidden = true
                onlineUserStackView.removeArrangedSubview(thirdUserIcon)
            }
        }
    }
    
    var listenerCount: Int = 0 {
        didSet {
            userCountLabel.text = listenerCount.string
        }
    }
    
    init(_ group: Entity.Group) {
        self.group = group
        super.init(frame: .zero)
        configureSubview()
        bindSubviewEvent()
        updateSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    
    func set(_ room: Entity.Group) {
//        switch room.state {
//        case .public:
//            publicButton.setTitle(R.string.localizable.roomPublic(), for: .normal)
//            publicButton.setBackgroundImage("592DFF".color().image, for: .normal)
//        case .private:
//            publicButton.setTitle(R.string.localizable.roomPrivate(), for: .normal)
//            publicButton.setBackgroundImage("E6309E".color().image, for: .normal)
//        }
//        kickButton.isHidden = !room.loginUserIsAdmin
        self.group = room
//        publicButton.isUserInteractionEnabled = room.loginUserIsAdmin
    }
    
    override func layoutSubviews() {
        backgroundLayer.frame = bounds
        layer.mask = nil
        addCorner(with: 24, corners: [.bottomLeft, .bottomRight])

    }
    
    private func bindSubviewEvent() {
        configView.actionHandler = { [weak self] action in
            switch action {
            case .setupCode:
                self?.actionHandler?(.setupCode)
            case .setupLink:
                self?.actionHandler?(.setupLink)
            case .setupNotes:
                self?.actionHandler?(.setupNotes)
            }
        }
    }
        
    private func updateSubview() {
        titleLabel.text = group.name
        topicNameLabel.text = group.topicName
        topicIcon.setImage(with: group.coverURL)
        coverView.setImage(with: group.cover)
        groupCountLabel.text = group.membersCount.string
        //first
//        userCountLabel.text = group.playerCount?.string
        configView.group = group
        onlineUserStackView.isHidden = group.onlineUserCount == 0
    }
    
    private func configureSubview() {
        topicContainer.addSubview(topicContainerBg)
        topicContainerBg.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        leaveButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        leaveButton.titleLabel?.numberOfLines = 0
        layer.insertSublayer(backgroundLayer, at: 0)
        backgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundLayer.endPoint = CGPoint(x: 1, y: 1)
        backgroundLayer.locations = [0, 0.5, 1]
        backgroundLayer.colors = ["4877CB".color().cgColor, "302D9A".color().cgColor, "14095B".color().cgColor,]

    }
    
    @IBAction func tapMembersAction(_ sender: Any) {
        actionHandler?(.memberList)
    }
    
    @IBAction func tapGroupAvatarAction(_ sender: Any) {
        actionHandler?(.groupInfo)
    }
    
    @IBAction func tapTopicAction(_ sender: Any) {
        actionHandler?(.topic)
    }
    
    @IBAction func leaveButtonAction(_ sender: Any) {
//        leaveHandler?()
        actionHandler?(.leave)
    }
}
