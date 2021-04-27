//
//  FansGroup.GroupMemberListViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/8.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup.GroupMemberListViewController {
    
    class MemberCell: UITableViewCell {
        
        private typealias UserView = AmongChat.Home.UserView
        private lazy var userView: UserView = {
            let v = UserView(.gray)
            return v
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
            
            contentView.addSubviews(views: userView)
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.bottom.equalToSuperview()
            }
        }
        
        func bind(user: Entity.UserProfile) {
            userView.bind(profile: user)
        }
        
    }
    
}

extension FansGroup.GroupMemberListViewController {
    
    class AddMemberCell: UITableViewCell {
        
        private let bag = DisposeBag()
        
        private lazy var icon: UIImageView = {
            let i = UIImageView(image: R.image.ac_group_add())
            return i
        }()
        
        private lazy var title: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.text = R.string.localizable.amongChatGroupAddMembers()
            lb.textColor = .white
            return lb
        }()
        
        var tapHandler: (() -> Void)? = nil
        
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
            
            contentView.addSubviews(views: icon, title)
            
            icon.snp.makeConstraints { (maker) in
                maker.leading.equalTo(20)
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(40)
            }
            
            title.snp.makeConstraints { (maker) in
                maker.leading.equalTo(icon.snp.trailing).offset(12)
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
            }
            
            let tap = UITapGestureRecognizer()
            contentView.addGestureRecognizer(tap)
            tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.tapHandler?()
                })
                .disposed(by: bag)
        }
        
    }
    
}
