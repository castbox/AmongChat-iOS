//
//  Social.SelectAvatarViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    
    class SelectAvatarViewController: WalkieTalkie.ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_profile_close(), for: .normal)
            return btn
        }()
                
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 45
            iv.layer.masksToBounds = true
            return iv
        }()
                
        private lazy var nameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()

        private lazy var avatarCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let interSpace: CGFloat = 20
            let hwRatio: CGFloat = 1
            let cellWidth = UIScreen.main.bounds.width - hInset * 2 - interSpace
            let cellHeight = cellWidth * hwRatio
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interSpace
            layout.minimumLineSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: 20, left: hInset, bottom: Frame.Height.safeAeraBottomHeight, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(AvatarCell.self, forCellWithReuseIdentifier: NSStringFromClass(AvatarCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
    }
    
}

extension Social.SelectAvatarViewController {
    
    // MARK: - UI Action
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
    
}

extension Social.SelectAvatarViewController {
    
    // MARK: - convinient
    private func setupLayout() {
        
        view.addSubviews(views: backBtn, avatarIV, nameLabel, avatarCollectionView)
        
        backBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.top.equalToSuperview().offset(16 + Frame.Height.safeAeraTopHeight)
            maker.width.height.equalTo(24)
        }
        
        avatarIV.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(90)
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(69)
        }
        
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview().offset(20)
            maker.top.equalTo(avatarIV.snp.bottom).offset(8)
        }
        
        avatarCollectionView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalTo(nameLabel.snp.bottom).offset(30)
        }
    }
    
    private func setupData() {
        
        Settings.shared.amongChatUserProfile.replay()
            .subscribe(onNext: { [weak self] (profile) in
                guard let profile = profile else { return }
                self?.configProfile(profile)
            })
            .disposed(by: bag)
    }
    
    private func configProfile(_ profile: Entity.UserProfile) {
        
        if let b = profile.birthday, !b.isEmpty {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            if let startDate = dateFormatter.date(from: b)  {
                
                let endDate = Date()
                
                let calendar = Calendar.current
                let calcAge = calendar.dateComponents([.year], from: startDate, to: endDate)
                
                if let age = calcAge.year?.string, !age.isEmpty {
                    nameLabel.text = "\(profile.name ?? ""), \(age)"
                } else {
                    nameLabel.text = profile.name
                }
            } else {
                nameLabel.text = profile.name
            }
        } else {
            nameLabel.text = profile.name
        }
        
        nameLabel.appendKern()
        
        avatarIV.setAvatarImage(with: profile.pictureUrl)
    }
    
}

extension Social.SelectAvatarViewController: UICollectionViewDataSource {

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(AvatarCell.self), for: indexPath)
        return cell
    }

}

extension Social.SelectAvatarViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
}

extension Social.SelectAvatarViewController {
    
    class AvatarCell: UICollectionViewCell {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            return iv
        }()
        
        private lazy var selectedIcon: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        private func setupLayout() {
            contentView.backgroundColor = UIColor(hex6: 0x222222)
            contentView.layer.cornerRadius = 12
            
            contentView.addSubviews(views: avatarIV, selectedIcon)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview().inset(34)
                maker.width.equalTo(avatarIV.snp.height).multipliedBy(1)
                maker.centerY.equalToSuperview()
            }
            
            selectedIcon.snp.makeConstraints { (maker) in
                maker.top.left.equalToSuperview()
            }
        }

    }
    
}
