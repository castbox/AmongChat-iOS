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
        
        private(set) lazy var layoutScrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            if #available(iOS 11.0, *) {
                s.contentInsetAdjustmentBehavior = .never
            }
            s.keyboardDismissMode = .onDrag
            return s
        }()
        
        private lazy var innerContainerView: UIView = {
            let v = UIView()
            return v
        }()
        
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
        
        private(set) lazy var appendViewContainer: UIView = {
            let v = UIView()
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
            setUpEvents()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func enlargeTopGbHeight(extraHeight: CGFloat) {
            
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
            
            addSubview(layoutScrollView)
            layoutScrollView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            layoutScrollView.addSubview(innerContainerView)
            innerContainerView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.width.equalTo(snp.width)
            }
            
            innerContainerView.addSubviews(views: topBg, addCoverBtn, nameTitleLabel, nameView,
                                           descriptionTitleLabel, descriptionView,
                                           topicTitleLabel, topicSetView, appendViewContainer)
            
            topBg.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(0)
                maker.height.equalTo(topBgHeight)
            }
            
            addCoverBtn.snp.makeConstraints { (maker) in
                maker.leading.equalTo(20)
                maker.top.equalTo(Frame.Height.safeAeraTopHeight + 49 + 24)
                maker.width.height.equalTo(97)
            }
            
            nameTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(22)
                maker.top.equalTo(topBg.snp.bottom).offset(24)
            }
            
            nameView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(56)
                maker.top.equalTo(nameTitleLabel.snp.bottom).offset(12)
            }
            
            descriptionTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(22)
                maker.top.equalTo(nameView.snp.bottom).offset(36)
            }
            
            descriptionView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(descriptionTitleLabel.snp.bottom).offset(12)
            }
            
            topicTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(22)
                maker.top.equalTo(descriptionView.snp.bottom).offset(36)
            }
            
            topicSetView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
                maker.top.equalTo(topicTitleLabel.snp.bottom).offset(12)
            }
            
            appendViewContainer.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.top.equalTo(topicSetView.snp.bottom)
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
            
            let textingView = Observable.merge(
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
            
            Observable.combineLatest(RxKeyboard.instance.visibleHeight.asObservable(), textingView)
                .subscribe(onNext: { [weak self] keyboardVisibleHeight, textingView in
                                    
                    guard let `self` = self else { return }
                    
                    guard keyboardVisibleHeight > 0 else {
                        self.layoutScrollView.contentOffset = .zero
                        return
                    }
                    
                    let rect = self.innerContainerView.convert(textingView.frame, to: self)
                    let distance = Frame.Screen.height - keyboardVisibleHeight - rect.maxY - 40
                    
                    guard distance < 0 else {
                        return
                    }
                    
                    UIView.animate(withDuration: RxKeyboard.instance.animationDuration) {
                        self.layoutScrollView.contentOffset.y = self.layoutScrollView.contentOffset.y - distance
                    }
                })
                .disposed(by: bag)
            
            layoutScrollView.rx.contentOffset
                .subscribe(onNext: { [weak self] (point) in
                    self?.enlargeTopGbHeight(extraHeight: -point.y)
                })
                .disposed(by: bag)
        }
        
    }
    
}
