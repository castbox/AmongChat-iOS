//
//  AmongChat.Home.RelationsViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class RelationsViewController: WalkieTalkie.ViewController {
        
        private lazy var profileBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_profile(), for: .normal)
            btn.addTarget(self, action: #selector(onProfileBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var bannerIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_home_banner())
            return i
        }()
        
        private lazy var createRoomBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_create(), for: .normal)
            btn.addTarget(self, action: #selector(onCreateRoomBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        override var screenName: Logger.Screen.Node.Start {
            return .friends
        }
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            hidesBottomBarWhenPushed = false
        }
        
    }
    
}

extension AmongChat.Home.RelationsViewController {
    
    private func setupLayout() {
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(60)
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        view.addSubviews(views: profileBtn, bannerIV, createRoomBtn)
        
        profileBtn.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(42)
            maker.left.equalToSuperview().inset(20)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        createRoomBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(20)
            maker.width.height.equalTo(42)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        bannerIV.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
        
    }
    
}

extension AmongChat.Home.RelationsViewController {

    //MARK: - UI Action
    
    @objc
    private func onProfileBtn() {
        Routes.handle("/profile")
    }
    
    @objc
    private func onCreateRoomBtn() {
        Routes.handle("/createRoom")
    }

}
