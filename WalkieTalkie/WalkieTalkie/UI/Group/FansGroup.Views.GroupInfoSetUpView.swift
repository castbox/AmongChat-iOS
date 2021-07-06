//
//  FansGroup.Views.GroupInfoSetUpView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/8.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup.Views {
    
    class GroupInfoSetUpView: UIView {
        
        private let bag = DisposeBag()
        
        private let topBgHeight = CGFloat(254.0)
        private let topBgTop: CGFloat = 0
        private let nameTitleLabelTop: CGFloat = 24
        private let nameTitleLabelHeight: CGFloat = 22
        private let nameViewHeight: CGFloat = 56
        private let nameViewTop: CGFloat = 12
        private let descriptionTitleLabelHeight: CGFloat = 22
        private let descriptionTitleLabelTop: CGFloat = 36
        private let descriptionViewHeight: CGFloat = 115
        private let descriptionViewTop: CGFloat = 12
        private let topicTitleLabelHeight: CGFloat = 22
        private let topicTitleLabelTop: CGFloat = 36
        private let topicSetViewHeight: CGFloat = 32
        private let topicSetViewTop: CGFloat = 12
        
        var viewHeight: CGFloat {
            
            let height = topBgTop + topBgHeight +
            nameTitleLabelTop + nameTitleLabelHeight +
            nameViewTop + nameViewHeight +
            descriptionTitleLabelTop + descriptionTitleLabelHeight +
            descriptionViewTop + descriptionViewHeight +
            topicTitleLabelTop + topicTitleLabelHeight +
            topicSetViewTop + topicSetViewHeight
            
            return height
        }
        
        private lazy var topBg: GroupBigCoverView = {
            let b = GroupBigCoverView()
            return b
        }()
        
        private(set) lazy var addCoverBtn: GroupAddCoverView = {
            let a = GroupAddCoverView()
            return a
        }()
        
        private lazy var nameTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.amongChatGroupName()
            return l
        }()
        
        private(set) lazy var nameView: GroupNameView = {
            let n = GroupNameView()
            return n
        }()
        
        private lazy var descriptionTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.amongChatGroupDescription()
            return l
        }()
        
        private(set) lazy var descriptionView: GroupDescriptionView = {
            let d = GroupDescriptionView()
            return d
        }()
        
        private lazy var topicTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.amongChatGroupTopic()
            return l
        }()
        
        private(set) lazy var topicSetView: GroupTopicSetView = {
            let t = GroupTopicSetView()
            return t
        }()
        
        var textViewObservable: Observable<UIView> {
            return Observable.merge(
                nameView.isEdtingRelay
                    .map({ [weak self] (isEditing) -> UIView? in
                        return isEditing ? self?.nameView : nil
                    }),
                descriptionView.isEdtingRelay
                    .map({ (isEditing) -> UIView? in
                        return isEditing ? self.descriptionView : nil
                    })
            )
            .filterNil()
        }
                
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
            setUpEvents()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func enlargeTopGbHeight(extraHeight: CGFloat) {
            
            guard extraHeight >= 0 else {
                return
            }
            
            topBg.snp.updateConstraints { (maker) in
                maker.top.equalTo(-extraHeight)
                maker.height.equalTo(topBgHeight + extraHeight)
            }
            
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
                        
            addSubviews(views: topBg, addCoverBtn, nameTitleLabel, nameView,
                        descriptionTitleLabel, descriptionView,
                        topicTitleLabel, topicSetView)
            
            topBg.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topBgTop)
                maker.height.equalTo(topBgHeight)
            }
            
            addCoverBtn.snp.makeConstraints { (maker) in
                maker.leading.equalTo(Frame.horizontalBleedWidth)
                maker.top.equalTo(Frame.Height.safeAeraTopHeight + 49 + 24)
                maker.width.height.equalTo(97)
            }
            
            nameTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(nameTitleLabelHeight)
                maker.top.equalTo(topBg.snp.bottom).offset(nameTitleLabelTop)
            }
            
            nameView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(nameViewHeight)
                maker.top.equalTo(nameTitleLabel.snp.bottom).offset(nameViewTop)
            }
            
            descriptionTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(descriptionTitleLabelHeight)
                maker.top.equalTo(nameView.snp.bottom).offset(descriptionTitleLabelTop)
            }
            
            descriptionView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.top.equalTo(descriptionTitleLabel.snp.bottom).offset(descriptionViewTop)
            }
            
            topicTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(topicTitleLabelHeight)
                maker.top.equalTo(descriptionView.snp.bottom).offset(topicTitleLabelTop)
            }
            
            topicSetView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(topicSetViewHeight)
                maker.top.equalTo(topicTitleLabel.snp.bottom).offset(topicSetViewTop)
                maker.bottom.equalToSuperview()
            }
            
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.endEditing(true)
                })
                .disposed(by: bag)
        }
        
        private func setUpEvents() {
            
            addCoverBtn.coverRelay.bind(to: topBg.coverRelay)
                .disposed(by: bag)
        }
        
    }
    
}
