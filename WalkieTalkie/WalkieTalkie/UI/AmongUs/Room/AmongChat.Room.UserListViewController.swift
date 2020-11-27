//
//  AmongChat.Room.UserListViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Room {
    
    class UserListViewController: WalkieTalkie.ViewController {
        
        private lazy var bgView: UIView = {
            let v = UIView()
            let ship = UIImageView(image: R.image.space_ship_bg())
            let star = UIImageView(image: R.image.star_bg())
            v.addSubviews(views: star, ship)
            star.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            ship.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }()
        
        private lazy var closeBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.icon_close(), for: .normal)
            btn.addTarget(self, action: #selector(onCloseBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var userCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.itemSize = CGSize(width: 32, height: 32)
            layout.minimumLineSpacing = 10
            layout.sectionInset = .zero
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
//            v.dataSource = self
//            v.delegate = self
            v.backgroundColor = nil
            return v
        }()
        
        private lazy var micSwitchBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onMicSwitchBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var shareBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onShareBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
    }
    
}

extension AmongChat.Room.UserListViewController {
    
    //MARK: - UI Action
    
    @objc
    private func onCloseBtn() {
        ChatRoomManager.shared.leaveChannel { [weak self] (_) in
            
            guard let `self` = self else { return }
            
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
            transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
            self.view.window!.layer.add(transition, forKey: kCATransition)
            self.dismiss(animated: true)
        }
    }
    
    @objc
    private func onMicSwitchBtn() {
        
    }
    
    @objc
    private func onShareBtn() {
        
    }
    
}

extension AmongChat.Room.UserListViewController {
    
    private func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hex6: 0x00011B)
        view.addSubviews(views: bgView, closeBtn)
        
        bgView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        closeBtn.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(44)
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(2)
            maker.right.equalTo(-6)
        }
    }
    
    private func showShareController(channelName: String) {
        let controller = R.storyboard.main.privateShareController()
        controller?.channelName = channelName
        controller?.showModal(in: self)
    }
    
}
