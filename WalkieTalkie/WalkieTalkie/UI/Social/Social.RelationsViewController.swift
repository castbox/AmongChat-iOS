//
//  Social.RelationsViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/31.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension Social {
    
    class RelationsViewController: ViewController, UIScrollViewDelegate {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.backNor(), for: .normal)
            return btn
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 16)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var followingBtn: WalkieButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = .clear
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onSegmentedBtn(sender:)), for: .primaryActionTriggered)
            btn.setTitleColor(.black, for: .normal)
            btn.tag = 0
            return btn
        }()
        
        private lazy var segmentedBtn: UIStackView = {
            let btnStack = UIStackView(arrangedSubviews: [followingBtn, followerBtn])
            btnStack.axis = .horizontal
            btnStack.spacing = 0
            btnStack.distribution = .fillEqually
            return btnStack
        }()
        
        private lazy var followerBtn: WalkieButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = .clear
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onSegmentedBtn(sender:)), for: .primaryActionTriggered)
            btn.setTitleColor(.black, for: .normal)
            btn.tag = 1
            return btn
        }()
        
        private lazy var segmentedIndicator: UIView = {
            let v = UIView()
            v.backgroundColor = .black
            return v
        }()

        private lazy var layoutScrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            s.delegate = self
            s.isPagingEnabled = true
            s.bounces = false
            return s
        }()
        
        enum Tab {
            case followingTab
            case followerTab
        }
        
        private let primitiveTab: Tab?
        
        init(_ primitiveTab: Tab? = nil) {
            self.primitiveTab = primitiveTab
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            
            Observable.combineLatest(Social.Module.shared.followingObservable(), Social.Module.shared.followerObservable())
                .subscribe(onNext: { [weak self] (followingList, followerList) in
                    
                    self?.followingBtn.setTitle("\(followingList.count) \(R.string.localizable.profileFollowing())", for: .normal)
                    self?.followingBtn.appendKern()
                    self?.followerBtn.setTitle("\(followerList.count) \(R.string.localizable.profileFollower())", for: .normal)
                    self?.followerBtn.appendKern()
                })
                .disposed(by: bag)
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            segmentedIndicator.snp.updateConstraints { (maker) in
                maker.width.equalTo(followerBtn.bounds.width)
            }
            
            layoutScrollView.contentSize = CGSize(width: layoutScrollView.bounds.width * 2, height: layoutScrollView.bounds.height)
            
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)
            
            view.addSubviews(views: backBtn, titleLabel, segmentedBtn, segmentedIndicator, layoutScrollView)
            
            let navLayoutGuide = UILayoutGuide()
            view.addLayoutGuide(navLayoutGuide)
            navLayoutGuide.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.height.equalTo(48)
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            backBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(navLayoutGuide)
                maker.left.equalToSuperview().offset(15)
                maker.width.height.equalTo(25)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(navLayoutGuide)
            }
            
            segmentedBtn.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.height.equalTo(44)
                maker.top.equalTo(navLayoutGuide.snp.bottom)
            }
            
            segmentedIndicator.snp.makeConstraints { (maker) in
                maker.top.equalTo(segmentedBtn.snp.bottom)
                maker.height.equalTo(1)
                maker.width.equalTo(0)
                maker.left.equalTo(0)
            }
            
            layoutScrollView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
                maker.top.equalTo(segmentedBtn.snp.bottom).offset(15)
            }
            
            let followingList = UserList.ViewController(with: .following)
            
            addChild(followingList)
            layoutScrollView.addSubview(followingList.view)
            followingList.view.snp.makeConstraints { (maker) in
                maker.top.left.bottom.equalToSuperview()
                maker.width.equalToSuperview()
                maker.height.equalToSuperview()
            }
            followingList.didMove(toParent: self)

            let followerList = UserList.ViewController(with: .follower)
            
            addChild(followerList)
            layoutScrollView.addSubview(followerList.view)
            followerList.view.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.left.equalTo(followingList.view.snp.right)
                maker.width.equalToSuperview()
                maker.height.equalToSuperview()
                maker.right.equalToSuperview()
            }
            followerList.didMove(toParent: self)

        }
        
        @objc
        private func onBackBtn() {
            navigationController?.popViewController()
        }
        
        @objc
        private func onSegmentedBtn(sender: UIButton) {
            let tag = sender.tag
            
            layoutScrollView.setContentOffset(CGPoint(x: view.bounds.width * CGFloat(Float(tag)), y: 0), animated: true)
        }
        
        // MARK: - UIScrollView
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView === layoutScrollView {
                let scrolledRatio = scrollView.contentOffset.x / scrollView.contentSize.width
                let barLeft = view.bounds.width * scrolledRatio
                segmentedIndicator.snp.updateConstraints { (maker) in
                    maker.left.equalTo(barLeft)
                }
            }
        }
        
    }
}
