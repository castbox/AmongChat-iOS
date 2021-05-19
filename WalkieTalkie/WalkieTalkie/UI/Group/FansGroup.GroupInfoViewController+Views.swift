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
    
    class GroupHeaderView: UIView {
        
        private let bag = DisposeBag()
                
        private let coverTop: CGFloat = Frame.Height.safeAeraTopHeight + 49 + 24
        private let coverSize = CGSize(width: 97, height: 97)
        private let nameTop = CGFloat(12)
        private let nameHeight = CGFloat(26)
        private let namePadding = Frame.horizontalBleedWidth
        private let descTop = CGFloat(4)
        private let descBottom = CGFloat(24)
        private let leaveBtnLayoutGuideHeight = CGFloat(86)
        private let leaveViewBottomSpace = CGFloat(22)
        
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
        
        private lazy var descriptionLabel: ExpandableLabel = {
            let l = ExpandableLabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0xFFFFFF, alpha: 0.65)
            l.numberOfLines = 0
            return l
        }()
                
        private lazy var leaveView: UIView = {
            let v = UIView()
            
            let leaveBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.layer.cornerRadius = 25
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                btn.setTitle(R.string.localizable.amongChatGroupLeaveGroup(), for: .normal)
                btn.setImage(R.image.ac_group_Leave(), for: .normal)
                btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
                btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
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
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(50)
                maker.top.equalTo(24)
            }
            v.isHidden = true
            return v
        }()
                
        private var groupInfo: FansGroup.GroupInfoViewController.GroupViewModel? = nil
        
        var leaveHandler: (() -> Void)? = nil
        var expandedHandler: (() -> Void)? = nil {
            didSet {
                descriptionLabel.expandedHandler = expandedHandler
            }
        }
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
            
            addSubviews(views: topBg, leaveView, coverView, nameLabel, descriptionLabel)
            
            topBg.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(0)
                maker.bottom.equalTo(leaveView.snp.top)
            }
            
            coverView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.top.equalTo(coverTop)
                maker.size.equalTo(coverSize)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(namePadding)
                maker.height.equalTo(nameHeight)
                maker.top.equalTo(coverView.snp.bottom).offset(nameTop)
            }
            
            descriptionLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(namePadding)
                maker.top.equalTo(nameLabel.snp.bottom).offset(descTop)
                maker.bottom.equalTo(topBg.snp.bottom).inset(descBottom)
            }
            
            leaveView.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.height.equalTo(0)
                maker.bottom.equalToSuperview().inset(leaveViewBottomSpace)
            }
            
        }
        
        private func setUpEvents() {
            
            coverView.coverRelay.bind(to: topBg.coverRelay)
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
            descriptionLabel.wholeString = groupInfo?.description
            
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
            
            let descHeight: CGFloat = descriptionLabel.textHeight
            
            var height = coverTop + coverSize.height + nameTop + nameHeight + descTop + descHeight + descBottom + leaveViewBottomSpace
            
            switch groupInfo?.userStatus {
            case .memeber:
                height = height + leaveBtnLayoutGuideHeight
            default:
                ()
            }
            
            return CGSize(width: bounds.width, height: height)
        }
        
    }
    
}

extension FansGroup.GroupInfoViewController {
    
    class ExpandableLabel: YYLabel {
        
        private var expanded = false
        private let shortenLength = 130
        var expandedHandler: (() -> Void)? = nil
        
        var wholeString: String? = nil {
            didSet {
                updateText()
            }
        }
        
        var textHeight: CGFloat {
            
            var textHeight: CGFloat = 0
            if let text = attributedText,
               let textSize = YYTextLayout(containerSize: CGSize(width: bounds.width, height: .greatestFiniteMagnitude), text: text)?.textBoundingSize {
                textHeight = textSize.height.ceil
            }
            
            return textHeight
        }
        
        private func updateText() {
            
            guard !expanded,
                  wholeString?.count ?? 0 > shortenLength else {
                attributedText = NSMutableAttributedString(string: String(wholeString ?? ""),
                                                           attributes: [
                                                            .font : font,
                                                            .foregroundColor: textColor
                                                           ])
                return
            }
            
            let moreAtt = NSAttributedString(string: " " + R.string.localizable.amongChatGroupInfoExpand(),
                                             attributes: [
                                                .font : font,
                                                .foregroundColor : UIColor.white
                                             ])
            
            let descAtt = NSMutableAttributedString(string: String(wholeString?.prefix(shortenLength) ?? ""),
                                                    attributes: [
                                                        .font : font,
                                                        .foregroundColor: textColor
                                                    ])
            
            descAtt.append(moreAtt)
            
            attributedText = descAtt
            
            textTapAction = { [weak self] (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) -> Void in
                
                guard let moreAttRange = descAtt.string.nsRange(of: moreAtt.string) else {
                    return
                }
                
                if NSIntersectionRange(range, moreAttRange).length > 0 {
                    self?.expanded = true
                    self?.updateText()
                    self?.expandedHandler?()
                }
            }
            
        }
        
        
    }
    
}
