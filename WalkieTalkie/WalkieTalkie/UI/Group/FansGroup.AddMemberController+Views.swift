//
//  FansGroup.AddMemberController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/31.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension FansGroup.AddMemberController {
    
    class MemberCell: UITableViewCell {
        
        private let bag = DisposeBag()
        
        private lazy var userView: AmongChat.Home.UserView = {
            let v = AmongChat.Home.UserView()
            return v
        }()
                
        private lazy var addBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.amongChatAdd(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
            return btn
        }()
        
        private lazy var inGroupLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.text = R.string.localizable.amongChatGroupAddMemberInGroup()
            return l
        }()
                
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            selectionStyle = .none
            
            contentView.addSubviews(views: userView, addBtn)
                        
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(buttonLayout.snp.leading).offset(-20)
            }
            
            addBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
        }
        
        func bind(viewModel: Entity.ContactFriend,
                  onAdd: @escaping () -> Void,
                  onAvatarTap: @escaping () -> Void) {
            userView.bind(viewModel: viewModel, onAvatarTap: onAvatarTap)
        }
        
    }
    
}
