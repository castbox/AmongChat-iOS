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
        
        private lazy var avatarIV: AvatarImageView = {
            let iv = AvatarImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.isUserInteractionEnabled = true
            return iv
        }()
        
        private lazy var avatarTap: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event.subscribe(onNext: { [weak self] (_) in
                self?.avatarTapHandler?()
            })
            .disposed(by: bag)
            return g
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            return lb
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
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.addHandler?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var inGroupLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.text = R.string.localizable.amongChatGroupAddMemberInGroup()
            l.textColor = UIColor(hex6: 0x898989)
            return l
        }()
        
        private var avatarTapHandler: (() -> Void)? = nil
        private var addHandler: (() -> Void)? = nil

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

            avatarIV.addGestureRecognizer(avatarTap)
            
            contentView.addSubviews(views: avatarIV, nameLabel, addBtn, inGroupLabel)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.leading.equalToSuperview().inset(20)
            }
            
            let textLayout = UILayoutGuide()
            contentView.addLayoutGuide(textLayout)
            
            textLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview()
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(avatarIV.snp.trailing).offset(12)
                maker.trailing.equalTo(addBtn.snp.leading).offset(-12)
                maker.centerY.equalTo(textLayout)
            }
            
            addBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            inGroupLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.centerY.equalTo(addBtn)
            }
            
        }
        
        func bind(viewModel: FansGroup.AddMemberController.MemeberViewModel,
                  onAdd: @escaping () -> Void,
                  onAvatarTap: @escaping () -> Void) {
            
            avatarIV.updateAvatar(with: viewModel.member)
            nameLabel.text = viewModel.member.name
            
            addBtn.isHidden = viewModel.inGroup
            inGroupLabel.isHidden = !viewModel.inGroup
            addHandler = onAdd
            avatarTapHandler = onAvatarTap
            
        }
        
    }
    
}
