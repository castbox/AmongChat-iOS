//
//  FansGroup.Views.GroupCells.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/19.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension FansGroup.Views {
    
    class GroupCellTagView: UIView {
        
        enum Style {
            case owned
            case online
        }
        
        private lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 12)
            l.textColor = UIColor(hex6: 0x000000)
            switch style {
            case .owned:
                l.text = R.string.localizable.groupOwner()
            case .online:
                l.text = R.string.localizable.groupOnline()
            }
            return l
        }()
        
        private lazy var dot: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x1FD300)
            v.layer.cornerRadius = 3.5
            return v
        }()
        
        private let style: Style
        
        init(_ style: Style) {
            self.style = style
            super.init(frame: .zero)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = bounds.height / 2
        }
        
        private func setUpLayout() {
            layer.masksToBounds = true
            layer.borderWidth = 2.5
            layer.borderColor = UIColor(hex6: 0x222222).cgColor
            backgroundColor = UIColor(hex6: 0xFFFFFF)
            
            switch style {
            case .owned:
                addSubviews(views: titleLabel)
                titleLabel.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 7.5, bottom: 4, right: 6.5))
                }
            case .online:
                addSubviews(views: titleLabel, dot)
                titleLabel.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 19, bottom: 4, right: 10))
                }
                
                dot.snp.makeConstraints { (maker) in
                    maker.width.height.equalTo(7)
                    maker.centerY.equalToSuperview()
                    maker.leading.equalTo(10)
                }
            }
            
        }
        
    }
    
    class OwnedGroupCell: UICollectionViewCell {
        
        enum Action {
            case start
            case edit
        }
        
        private let bag = DisposeBag()
        
        private lazy var editButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitle(R.string.localizable.groupItemEdit(), for: .normal)
            btn.layer.cornerRadius = 19
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.actionHandler?(.edit)
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var startButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(UIColor(hex6: 0x000000), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitle(R.string.localizable.groupItemStartLive(), for: .normal)
            btn.layer.cornerRadius = 19
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.actionHandler?(.start)
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var groupIconView: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            return l
        }()
        
        private(set) lazy var tagView: GroupCellTagView = {
            let t = GroupCellTagView(.owned)
            return t
        }()
        
        private lazy var bgView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.layer.cornerRadius = 12
            return v
        }()
        
        private var actionHandler: ((Action) -> Void)?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: bgView, groupIconView, tagView, titleLabel, editButton, startButton)
            
            bgView.snp.makeConstraints { (maker) in
                maker.top.bottom.trailing.equalToSuperview()
                maker.leading.equalTo(16)
            }
            
            groupIconView.snp.makeConstraints { (maker) in
                maker.leading.centerY.equalToSuperview()
                maker.top.equalTo(16)
                maker.width.equalTo(groupIconView.snp.height)
            }
            
            tagView.snp.makeConstraints { (maker) in
                maker.top.equalTo(6)
                maker.trailing.equalTo(groupIconView).offset(2.5)
                maker.height.equalTo(24)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.trailing.equalToSuperview().inset(16)
                maker.height.equalTo(25)
                maker.leading.equalTo(groupIconView.snp.trailing).offset(12)
            }
            
            editButton.snp.makeConstraints { (maker) in
                maker.leading.equalTo(titleLabel)
                maker.height.equalTo(38)
                maker.bottom.equalTo(groupIconView)
            }
            
            startButton.snp.makeConstraints { (maker) in
                maker.leading.equalTo(editButton.snp.trailing).offset(16)
                maker.trailing.equalTo(titleLabel)
                maker.bottom.height.width.equalTo(editButton)
            }
        }
        
        func bindData(_ group: Entity.Group, actionHandler: ((Action) -> Void)? = nil) {
            titleLabel.text = group.name
            groupIconView.setImage(with: group.cover.url)
            self.actionHandler = actionHandler
        }
        
    }
    
}

extension FansGroup.Views {
    
    class JoinedGroupCell: UICollectionViewCell {
        
        private lazy var groupIconView: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            return l
        }()
        
        private lazy var descLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0x898989)
            l.numberOfLines = 2
            return l
        }()
        
        private(set) lazy var topicView: FansGroup.Views.GroupTopicView = {
            let v = FansGroup.Views.GroupTopicView()
            return v
        }()
        
        private lazy var memberIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_group_room_count())
            return i
        }()
        
        private lazy var memberCountLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            return l
        }()
        
        private lazy var tagView: GroupCellTagView = {
            let t = GroupCellTagView(.online)
            return t
        }()
        
        private lazy var bgView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.layer.cornerRadius = 12
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: bgView, groupIconView, tagView, titleLabel, descLabel, topicView, memberIcon, memberCountLabel)
            
            bgView.snp.makeConstraints { (maker) in
                maker.top.bottom.trailing.equalToSuperview()
                maker.leading.equalTo(16)
            }
            
            groupIconView.snp.makeConstraints { (maker) in
                maker.leading.centerY.equalToSuperview()
                maker.top.equalTo(16)
                maker.width.equalTo(groupIconView.snp.height)
            }
            
            tagView.snp.makeConstraints { (maker) in
                maker.top.equalTo(6)
                maker.trailing.equalTo(groupIconView).offset(2.5)
                maker.height.equalTo(24)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.trailing.equalToSuperview().inset(16)
                maker.height.equalTo(25)
                maker.leading.equalTo(groupIconView.snp.trailing).offset(12)
            }
            
            descLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(titleLabel)
                maker.top.equalTo(titleLabel.snp.bottom)
            }
            
            topicView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(titleLabel)
                maker.bottom.equalTo(groupIconView)
                maker.height.equalTo(24)
                maker.trailing.lessThanOrEqualTo(memberIcon.snp.leading).offset(-12)
            }
            
            memberIcon.snp.makeConstraints { (maker) in
                maker.top.equalTo(memberCountLabel)
                maker.trailing.equalTo(memberCountLabel.snp.leading).offset(-4)
            }
            
            memberCountLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(memberIcon.snp.trailing).offset(2)
                maker.height.equalTo(19)
                maker.bottom.equalTo(groupIconView)
                maker.trailing.equalTo(titleLabel)
            }
        }
        
        func bindData(_ group: Entity.Group) {
            
            groupIconView.setImage(with: group.cover.url)
            titleLabel.text = group.name
            descLabel.text = group.description
            memberCountLabel.text = "\(group.membersCount)"
            topicView.coverSourceRelay.accept(group.coverURL)
            topicView.nameRelay.accept(group.topicName)
            tagView.isHidden = group.status == 0
            
        }

    }
    
}
