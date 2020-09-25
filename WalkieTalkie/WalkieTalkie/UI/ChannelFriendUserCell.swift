//
//  ChannelFriendUserCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

class ChannelFriendUserCell: UITableViewCell {

    private lazy var userView: Social.UserList.UserView = {
        let v = Social.UserList.UserView()
        return v
    }()
    
    private lazy var inviteBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(onInviteBtn), for: .primaryActionTriggered)
        btn.setImage(R.image.user_list_invite(), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        return btn
    }()
    
    private var user: Social.UserList.UserViewModel!
    var inviteHandler: ((String) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.5)
        contentView.addSubviews(views: userView, inviteBtn)
        
        userView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(15)
            maker.right.equalTo(inviteBtn.snp.left).offset(-10)
        }
        
        inviteBtn.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-15)
            maker.width.height.equalTo(30)
        }
    }
    
    @objc
    private func onInviteBtn() {
        // invite_clk log
        GuruAnalytics.log(event: "invite_clk", category: "user_list", name: nil, value: nil, content: nil)
        //
        user.invite()
        inviteBtn.isEnabled = false
        inviteHandler?(user.userId)
    }
    
    func configView(with viewModel: Social.UserList.UserViewModel, hasInvited: Bool) {
        user = viewModel
        userView.configView(with: viewModel)
        inviteBtn.isEnabled = viewModel.invitable && !hasInvited
    }
}
