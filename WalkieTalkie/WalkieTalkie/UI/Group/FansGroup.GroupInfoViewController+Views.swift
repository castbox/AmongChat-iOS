//
//  FansGroup.GroupInfoViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher
import YYText

extension FansGroup.GroupInfoViewController {
    
    class MemberCell: UITableViewCell {
        
        private typealias UserView = AmongChat.Home.UserView
        private lazy var userView: UserView = {
            let v = UserView()
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
        
        func bind(user: Entity.UserProfile,
                  onAvatarTap: @escaping () -> Void) {
            userView.bind(profile: user, onAvatarTap: onAvatarTap)
        }
        
    }
    
}

extension FansGroup.GroupInfoViewController {
    
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


extension FansGroup.GroupInfoViewController {
    
    class GroupHeaderView: UIView {
        
        private let bag = DisposeBag()
        
        private let descriptionLength = 130
        
        private let nameTop = CGFloat(226)
        private let nameHeight = CGFloat(26)
        private let namePadding = CGFloat(20)
        private let descTop = CGFloat(255)
        private let descBottom = CGFloat(24)
        private let leaveBtnLayoutGuideHeight = CGFloat(85)
        
        private lazy var topBg: FansGroup.Views.GroupBigCoverView = {
            let b = FansGroup.Views.GroupBigCoverView()
            return b
        }()
        
        private lazy var coverView: FansGroup.Views.GroupAddCoverView = {
            let a = FansGroup.Views.GroupAddCoverView()
            a.editable = false
            return a
        }()
        
        private lazy var nameLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            return l
        }()
        
        private lazy var descriptionLabel: YYLabel = {
            let l = YYLabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0xFFFFFF, alpha: 0.65)
            l.numberOfLines = 0
            return l
        }()
        
        private lazy var expandBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setTitle(R.string.localizable.amongChatGroupInfoExpand(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoBold(size: 14)
            return btn
        }()
        
        private lazy var leaveView: UIView = {
            let v = UIView()
            
            let leaveBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.layer.cornerRadius = 25
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                btn.setTitle(R.string.localizable.amongChatGroupLeaveGroup(), for: .normal)
                btn.setTitleColor(UIColor(hex6: 0xFB5858), for: .normal)
                btn.backgroundColor = UIColor(hex6: 0x232323)
                btn.rx.controlEvent(.primaryActionTriggered)
                    .subscribe(onNext: { [weak self] (_) in
                        self?.leaveHandler?()
                    })
                    .disposed(by: bag)
                return btn
            }()
            
            v.addSubview(leaveBtn)
            leaveBtn.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(50)
                maker.top.equalTo(24)
            }
            v.isHidden = true
            return v
        }()
        
        private var expanded = false
        
        private var groupInfo: FansGroup.GroupInfoViewController.GroupViewModel? = nil
        
        var leaveHandler: (() -> Void)? = nil
        var expandedHandler: (() -> Void)? = nil
        var editHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
            setUpEvents()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            
            addSubviews(views: topBg, leaveView, coverView, nameLabel, descriptionLabel, expandBtn)
            
            topBg.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(0)
                maker.bottom.equalTo(leaveView.snp.top)
            }
            
            coverView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(20)
                maker.top.equalTo(117)
                maker.width.height.equalTo(97)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(namePadding)
                maker.height.equalTo(nameHeight)
                maker.top.equalTo(nameTop)
            }
            
            descriptionLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(namePadding)
                maker.top.equalTo(descTop)
                maker.bottom.equalTo(topBg.snp.bottom).offset(-24)
            }
            
            leaveView.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.height.equalTo(0)
            }
            
        }
        
        private func setUpEvents() {
            
            coverView.coverRelay.bind(to: topBg.coverRelay)
                .disposed(by: bag)
            
            descriptionLabel.rx.observe(String.self, "text")
                .subscribe(onNext: { [weak self] (image) in
                    
                    guard let `self` = self,
                          self.expanded else { return }
                    
                    
                })
                .disposed(by: bag)
            
        }
        
        func enlargeTopGbHeight(extraHeight: CGFloat) {
            
            guard extraHeight >= 0 else {
                return
            }
            
            topBg.snp.updateConstraints { (maker) in
                maker.top.equalTo(-extraHeight)
            }
            
        }
        
        func bindViewModel(_ viewModel: FansGroup.GroupInfoViewController.GroupViewModel) {
            
            groupInfo = viewModel
            
            if let cover = viewModel.cover?.url {
                KingfisherManager.shared.retrieveImageObservable(with: cover)
                    .bind(to: coverView.coverRelay)
                    .disposed(by: bag)
            }
            
            nameLabel.text = viewModel.name
            updateDescriptionText()
            
            switch groupInfo?.userStatus {
            case .memeber:
                leaveView.isHidden = false
                leaveView.snp.updateConstraints { (maker) in
                    maker.height.equalTo(leaveBtnLayoutGuideHeight)
                }
            default:
                leaveView.isHidden = true
                leaveView.snp.updateConstraints { (maker) in
                    maker.height.equalTo(0)
                }
            }
        }
        
        var viewSize: CGSize {
            
            let descHeight = descriptionLabel.text?.height(forConstrainedWidth: bounds.width - namePadding * 2, font: descriptionLabel.font).ceil ?? 0
            
            var height = descTop + descHeight + descBottom
            
            switch groupInfo?.userStatus {
            case .memeber:
                height = height + leaveBtnLayoutGuideHeight
            default:
                ()
            }
            
            return CGSize(width: bounds.width, height: height)
        }
        
        private func updateDescriptionText() {
            
            guard !expanded,
                  groupInfo?.description?.count ?? 0 > descriptionLength else {
                descriptionLabel.text = groupInfo?.description
                return
            }
            
            let moreAtt = NSAttributedString(string: " " + R.string.localizable.amongChatGroupInfoExpand(),
                                             attributes: [
                                                .font : descriptionLabel.font,
                                                .foregroundColor : UIColor.white
                                             ])
            
            let descAtt = NSMutableAttributedString(string: String(groupInfo?.description?.prefix(descriptionLength) ?? ""),
                                                    attributes: [
                                                        .font : descriptionLabel.font,
                                                        .foregroundColor: descriptionLabel.textColor
            ])
            
            descAtt.append(moreAtt)
            
            descriptionLabel.attributedText = descAtt
                        
            descriptionLabel.textTapAction = { [weak self] (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) -> Void in
                
                guard let moreAttRange = descAtt.string.nsRange(of: moreAtt.string) else {
                    return
                }
                
                if NSIntersectionRange(range, moreAttRange).length > 0 {
                    self?.expanded = true
                    self?.updateDescriptionText()
                    self?.expandedHandler?()
                }
            }

            
        }
        
    }
    
}
