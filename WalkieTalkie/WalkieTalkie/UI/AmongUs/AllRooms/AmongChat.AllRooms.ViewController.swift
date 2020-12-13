//
//  AmongChat.AllRooms.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/13.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.AllRooms {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private typealias ChannelCell = AmongChat.AllRooms.ChannelCell
        private typealias MoreCell = AmongChat.AllRooms.MoreCell
        private typealias HashTag = AmongChat.Home.HashTag
        private typealias ChannelCategory = FireStore.ChannelCategory
        
        // MARK: - members
        
        private lazy var bgImageView: UIImageView = {
            let i = UIImageView(image: R.image.star_bg())
            return i
        }()
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.backNor()?.withRenderingMode(.alwaysTemplate), for: .normal)
            btn.tintColor = UIColor.white.alpha(0.8)
            return btn
        }()
                
        private lazy var hashTagCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 30
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2)
            layout.itemSize = CGSize(width: cellWidth, height: 60)
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 12, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(ChannelCell.self, forCellWithReuseIdentifier: NSStringFromClass(ChannelCell.self))
            v.register(MoreCell.self, forCellWithReuseIdentifier: NSStringFromClass(MoreCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var hashTags: [HashTag] = {
            return FireStore.shared.channels.map { mapHastTag(from: $0) }
        }()
        
//        private var hudRemoval: (() -> Void)? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
    }
    
}

extension AmongChat.AllRooms.ViewController {
    
    // MARK: - UI Action
    
    @objc
    private func onBackBtn() {
        navigationController?.popViewController()
    }
    
}

extension AmongChat.AllRooms.ViewController {
    
    // MARK: - convinience
    
    private func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hex6: 0x00011B)
        view.addSubviews(views: bgImageView, backBtn, hashTagCollectionView)
        
        bgImageView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(15)
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(11.5)
            maker.width.height.equalTo(25)
        }
        
        hashTagCollectionView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.top.equalTo(backBtn.snp.bottom)
        }
        
    }
    
    private func mapHastTag(from channelCategory: ChannelCategory) -> HashTag {
        return HashTag(channelCategory: channelCategory) { [weak self] in
            guard let `self` = self else { return }
//            self.hudRemoval =
            let _ = self.view.raft.show(.loading, userInteractionEnabled: false)
            AmongChat.Home.ViewController.shared.joinRoom(with: FireStore.shared.findARoom(of: channelCategory))
            Logger.Channel.logChannelCategoryClick(id: channelCategory.id)
        }
    }

}

extension AmongChat.AllRooms.ViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashTags.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let hashTag = hashTags.safe(indexPath.item) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ChannelCell.self), for: indexPath)
            if let cell = cell as? ChannelCell {
                cell.configCell(with: hashTag)
            }
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(MoreCell.self), for: indexPath)
        }
    }
    
}

extension AmongChat.AllRooms.ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let hashTag = hashTags.safe(indexPath.item) {
            hashTag.didSelect()
        }
    }
    
}
