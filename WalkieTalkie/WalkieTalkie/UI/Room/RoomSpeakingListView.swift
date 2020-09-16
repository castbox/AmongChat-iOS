//
//  RoomSpeakingListView.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/3.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

class RoomSpeakingListView: UIView {
    
    private lazy var speakersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 32, height: 32)
        layout.minimumLineSpacing = 10
        layout.sectionInset = .zero
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.register(MicUserCell.self, forCellWithReuseIdentifier: NSStringFromClass(MicUserCell.self))
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.dataSource = self
        v.delegate = self
        v.backgroundColor = nil
        return v
    }()
    
    private lazy var userCountLabel: WalkieLabel = {
        let lb = WalkieLabel()
        lb.font = R.font.nunitoBold(size: 11)
        lb.textColor = UIColor(hex6: 0xF1F1F1, alpha: 1.0)
        return lb
    }()
    
    private lazy var moreUserBtn: UIView = {
        let btn = UIView()
        btn.backgroundColor = UIColor(hex6: 0x363636, alpha: 0.3)
        let tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(onMoreUserBtn))
        btn.addGestureRecognizer(tapGR)
        
        let iconIV = UIImageView(image: R.image.speak_list_user())
        btn.addSubviews(views: iconIV, self.userCountLabel)
        iconIV.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(15)
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(8)
        }
        
        self.userCountLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(iconIV.snp.right).offset(5)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-8)
        }
        
        btn.layer.cornerRadius = 15
        return btn
    }()
    
    private var userList: [ChannelUserViewModel] = [] {
        didSet {
            speakersCollectionView.reloadData()
        }
    }
    
    private var minimumListLength: Int = FireStore.ChannelConfig.default.gSpeakerLimit {
        didSet {
            speakersCollectionView.reloadData()
        }
    }
    
    var moreUserBtnAction: (() -> Void)? = nil
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: 50)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        let _ = ChannelUserListViewModel.shared.speakingUserObservable
            .subscribe(onNext: { [weak self] (users) in
                self?.userList = users
            })
        
        let _ = ChannelUserListViewModel.shared.userObservable
            .subscribe(onNext: { [weak self] (users) in
                self?.userCountLabel.text = "\(users.count)"
                self?.userCountLabel.appendKern()
            })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        addSubviews(views: speakersCollectionView, moreUserBtn)
        moreUserBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(15)
            maker.width.equalTo(45)
            maker.height.equalTo(30)
            maker.centerY.equalToSuperview()
        }
        
        speakersCollectionView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview().inset(9)
            maker.right.equalTo(moreUserBtn.snp.left).offset(-16)
        }
    }
    
    @objc
    private func onMoreUserBtn() {
        moreUserBtnAction?()
    }
    
    func update(with room: Room) {
        if room.name.isEmpty {
            moreUserBtn.isUserInteractionEnabled = false
            minimumListLength = FireStore.ChannelConfig.default.gSpeakerLimit
        } else {
            moreUserBtn.isUserInteractionEnabled = true
            minimumListLength = FireStore.channelConfig.maximumSpeakers(room)
        }
    }
}

fileprivate extension RoomSpeakingListView {
    
    class MicUserCell: UICollectionViewCell {
        
        
        private lazy var micView: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        private lazy var avatarBorder: UIView = {
            let v = UIView()
            v.layer.borderWidth = 0.5
            v.layer.borderColor = UIColor(hex6: 0xFFFFFF, alpha: 0.5).cgColor
            v.layer.cornerRadius = 15.5
            v.clipsToBounds = true
            return v
        }()

        private lazy var userAvatar: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 15
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var prefixLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBlack(size: 11)
            lb.textColor = UIColor(hex6: 0xF8F8F8)
            return lb
        }()
        
        private var avatarDisposable: Disposable?
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutIfNeeded() {
            super.layoutIfNeeded()
            avatarBorder.layer.cornerRadius = avatarBorder.bounds.width / 2
        }        
        
        private func setupLayout() {
            contentView.addSubviews(views: avatarBorder, userAvatar, micView, prefixLabel)
            
            userAvatar.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(30)
                maker.center.equalToSuperview()
            }
            
            prefixLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(userAvatar)
            }
            
            avatarBorder.snp.makeConstraints { (maker) in
                maker.edges.equalTo(userAvatar).inset(-0.5)
            }
                        
            micView.snp.makeConstraints { (maker) in
                maker.right.bottom.equalTo(userAvatar)
                maker.width.height.equalTo(15)
            }
        }
        
        func configWithViewModel(_ userViewModel: ChannelUserViewModel?) {
            avatarDisposable?.dispose()
            if let userViewModel = userViewModel {
                let user = userViewModel.channelUser
                avatarDisposable = userViewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
                    guard let `self` = self else { return }
                    
                    if let _ = image {
                        self.userAvatar.backgroundColor = nil
                    } else {
                        self.userAvatar.backgroundColor = user.iconColor.color()
                    }
                    self.userAvatar.image = image
                })
                
                micView.image = R.image.speak_list_mic()
                
                prefixLabel.text = user.prefix
                prefixLabel.isHidden = (userViewModel.firestoreUser != nil)

            } else {
                userAvatar.image = R.image.speak_list_add()
                userAvatar.backgroundColor = nil
                micView.image = nil
                prefixLabel.text = nil
                prefixLabel.isHidden = true
            }
        }
        
    }
}

extension RoomSpeakingListView: UICollectionViewDataSource {
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return max(userList.count, minimumListLength)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(MicUserCell.self), for: indexPath)
        if let cell = cell as? MicUserCell {
            cell.configWithViewModel(userList.safe(indexPath.item))
        }
        return cell
    }
    
}

extension RoomSpeakingListView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}
