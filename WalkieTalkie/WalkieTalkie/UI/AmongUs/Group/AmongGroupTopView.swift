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
    }
    
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var groupCountLabel: UILabel!
    
    @IBOutlet weak var leaveButton: BottomTitleButton!
    @IBOutlet weak var topicIcon: UIImageView!
    @IBOutlet weak var topicNameLabel: UILabel!
    @IBOutlet weak var configView: AmongGroupTopicConfigView!
    @IBOutlet weak var firstUserIcon: UIImageView!
    @IBOutlet weak var secondUserIcon: UIImageView!
    @IBOutlet weak var thirdUserIcon: UIImageView!
    @IBOutlet weak var userCountLabel: UILabel!

    private lazy var backgroundLayer = CAGradientLayer()
    
//    var room: Entity.Room?
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
    
    var room: Entity.GroupRoom {
        didSet {
            updateSubview()
        }
    }
    
    init(_ room: Entity.GroupRoom) {
        self.room = room
        super.init(frame: .zero)
        configureSubview()
        bindSubviewEvent()
        updateSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func layoutSubviews() {
        backgroundLayer.frame = bounds
        layer.mask = nil
        addCorner(with: 24, corners: [.bottomLeft, .bottomRight])

    }
    
    private func bindSubviewEvent() {
        
    }
        
    private func updateSubview() {
//        switch room.topicType {
//        case .amongus:
//            justChillingInfoView.isHidden = true
//            infoWithNicknameView.isHidden = true
//            amongSetupView.isHidden = room.isValidAmongConfig
//            amongInfoView.isHidden = !room.isValidAmongConfig
//            amongInfoView.room = room
////            amongSetupView.isUserInteractionEnabled = room.loginUserIsAdmin
////            justChillingInfoView.isUserInteractionEnabled = room.loginUserIsAdmin
//        case .chilling:
//            justChillingInfoView.isHidden = false
//            amongSetupView.isHidden = true
//            amongInfoView.isHidden = true
//            infoWithNicknameView.isHidden = true
//            justChillingInfoView.room = room
//
//        case .roblox,
//             .fortnite,
//             .freefire,
//             .minecraft,
//             .mobilelegends,
//             .pubgmobile,
//             .animalCrossing,
//             .brawlStars,
//             .callofduty:
//
//            justChillingInfoView.isHidden = true
//            amongSetupView.isHidden = true
//            amongInfoView.isHidden = true
//            infoWithNicknameView.isHidden = false
//            infoWithNicknameView.room = room
//
//        default:
//            justChillingInfoView.isHidden = false
//            amongSetupView.isHidden = true
//            amongInfoView.isHidden = true
//            justChillingInfoView.room = room
////            justChillingInfoView.isUserInteractionEnabled = room.loginUserIsAdmin
//        }
        
//        if room.topicType.productId > 0 {
//            openGameButton.isHidden = false
//            nameLabel.isHidden = true
//            gameIconTop.constant = 14.5
//        } else {
//            openGameButton.isHidden = true
//            nameLabel.isHidden = false
//            nameLabel.text = room.topicName
//            gameIconTop.constant = 18.5
//        }
    }
    
    private func configureSubview() {
//        publicButton.titleLabel?.adjustsFontSizeToFitWidth = true
        leaveButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
//        leaveButton.titleLabel?.numberOfLines = 0
        layer.insertSublayer(backgroundLayer, at: 0)
        backgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundLayer.endPoint = CGPoint(x: 1, y: 1)
        backgroundLayer.locations = [0, 0.5, 0.75]
        backgroundLayer.colors = ["65F0FF".color().cgColor, "3C40B1".color().cgColor, "0D0063".color().cgColor,]

    }
    
    func set(_ room: Entity.GroupRoom) {
//        switch room.state {
//        case .public:
//            publicButton.setTitle(R.string.localizable.roomPublic(), for: .normal)
//            publicButton.setBackgroundImage("592DFF".color().image, for: .normal)
//        case .private:
//            publicButton.setTitle(R.string.localizable.roomPrivate(), for: .normal)
//            publicButton.setBackgroundImage("E6309E".color().image, for: .normal)
//        }
//        kickButton.isHidden = !room.loginUserIsAdmin
        self.room = room
//        publicButton.isUserInteractionEnabled = room.loginUserIsAdmin
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
