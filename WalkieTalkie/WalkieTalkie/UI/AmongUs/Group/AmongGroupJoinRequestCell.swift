//
//  AmongGroupJoinRequestCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AmongGroupJoinRequestCell: UITableViewCell {
    enum Action {
        case accept
        case reject
        case ignore
    }
    
    enum ButtonStyle {
        case applyGroup
        case applyOnSeat
    }
    
    private lazy var userView: AmongChat.Home.UserView = {
        let v = AmongChat.Home.UserView()
        return v
    }()
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var style: ButtonStyle = .applyGroup {
        didSet {
            switch style {
            case .applyOnSeat:
                leftButton.setTitle(R.string.localizable.groupRoomReject(), for: .normal)
            case .applyGroup:
                leftButton.setTitle(R.string.localizable.groupRoomIgnore(), for: .normal)
            }
            rightButton.setTitle(R.string.localizable.groupRoomAccept(), for: .normal)
        }
    }
    
    var actionHandler: ((Action) -> Void)?
    
    private var profile: Entity.UserProfile?
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubview()
        bindSubviewEvent()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubview()
        bindSubviewEvent()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(_ profile: Entity.UserProfile?, showFollowsCount: Bool = false, verifyStayle: AvatarImageView.VerifyIconStyle = .gray) {
        self.profile = profile
        guard let profile = profile else {
            return
        }
        userView.bind(viewModel: profile, showFollowersCount: showFollowsCount) {
            
        }
        userView.setVerifyIcon(style: verifyStayle)
    }
    
    func bindSubviewEvent() {
        
    }
    
    func configureSubview() {
//        contentView.backgroundColor = .clear
        
        contentView.addSubviews(views: userView)

        userView.snp.makeConstraints { (maker) in
            maker.leading.top.equalToSuperview().offset(20)
            maker.trailing.equalTo(-20)
            maker.height.equalTo(40)
        }
    }
    @IBAction func rightButtonAction(_ sender: Any) {
        actionHandler?(.accept)
    }
    
    @IBAction func leftButtonAction(_ sender: Any) {
        actionHandler?(style == .applyGroup ? .ignore: .reject)
    }
    
}
