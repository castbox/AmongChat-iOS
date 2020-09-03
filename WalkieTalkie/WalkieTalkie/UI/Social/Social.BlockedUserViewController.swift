//
//  Social.BlockedUserViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    
    class BlockedUserViewController: ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.backNor(), for: .normal)
            return btn
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 16)
            lb.text = R.string.localizable.socialBlockedUserTitle()
            lb.textColor = .black
            lb.appendKern()
            return lb
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)

            view.addSubviews(views: backBtn, titleLabel)
            
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
            
            let blockList = UserList.ViewController(with: .blocked)
            
            addChild(blockList)
            view.addSubview(blockList.view)
            blockList.view.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(navLayoutGuide.snp.bottom).offset(25)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            blockList.didMove(toParent: self)
            
        }
        
        @objc
        private func onBackBtn() {
            navigationController?.popViewController()
        }
    }
    
}
