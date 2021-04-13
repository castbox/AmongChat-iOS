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
                
        private typealias UserView = AmongChat.Home.UserView
        private lazy var userView: UserView = {
            let v = UserView()
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
            l.textAlignment = .center
            l.adjustsFontSizeToFitWidth = true
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
            
            contentView.addSubviews(views: userView, addBtn, inGroupLabel)
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(addBtn.snp.leading).offset(-12)
            }
                        
            addBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            inGroupLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.centerY.equalTo(addBtn)
            }
            
            addBtn.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            addBtn.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            userView.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            userView.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            
        }
        
        func bind(viewModel: FansGroup.AddMemberController.MemeberViewModel, onAdd: @escaping () -> Void) {
            
            userView.bind(profile: viewModel.member)
            
            addBtn.isHidden = viewModel.inGroup
            inGroupLabel.isHidden = !viewModel.inGroup
            addHandler = onAdd
            
        }
        
    }
    
}
