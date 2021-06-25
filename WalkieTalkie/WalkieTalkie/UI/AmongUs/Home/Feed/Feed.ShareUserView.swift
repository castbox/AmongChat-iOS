//
//  Feed.ShareUserView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 22/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MessageUI

extension Feed {
    class ShareUserView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
        
        private lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 66, height: 94)
            layout.minimumLineSpacing = 0
            layout.minimumLineSpacing = 12
            layout.headerReferenceSize = CGSize(width: 11, height: 0)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(nibWithCellClass: FeedShareUserCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            return v
        }()
        
        var dataSource: [Entity.UserProfile] = [] {
            didSet {
                collectionView.reloadData()
            }
        }
        
        private var selectedUsers: [Entity.UserProfile] = [] {
            didSet {
                selectedUsersHandler?(selectedUsers)
                collectionView.reloadData()
            }
        }
        
        var selectedUsersHandler: (([Entity.UserProfile]) -> Void)?
        var tapMoreHandler: CallBack?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(collectionView)
            collectionView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.height.equalTo(94)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func bind(_ dataSource: [Entity.UserProfile]) {
            var items = dataSource
            if let moreItem = try? JSONDecoder().decodeAnyData(Entity.UserProfile.self, from: ["uid": 0]) {
                items.append(moreItem)
            }
            self.dataSource = items
        }
        
        // MARK: - UICollectionViewDataSource
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return dataSource.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withClass: FeedShareUserCell.self, for: indexPath)
            let item = dataSource[indexPath.item]
            cell.bind(item, isSelected: selectedUsers.contains(where: { $0.uid == item.uid }))
            return cell
        }
        
        // MARK: - UICollectionViewDelegate
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let item = dataSource.safe(indexPath.item) else {
                return
            }
            if item.uid == 0 {
                tapMoreHandler?()
            } else  if selectedUsers.contains(where: { $0.uid == item.uid }) {
                selectedUsers.removeFirst(where: { $0.uid == item.uid })
            } else {
                guard selectedUsers.count < 10 else {
                    containingController?.view.raft.autoShow(.text(R.string.localizable.feedShareUserSelectedReachMax()))
                    return
                }
                selectedUsers.append(item)
            }
        }
        
    }
    
    class ShareBar: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
        
        enum ShareSource {
            case message
            case sms
            case snapchat
            case copyLink
            case shareLink
            case more
            
            var icon: UIImage? {
                switch self {
                case .message:
                    return R.image.ac_feed_share_message()
                case .sms:
                    return R.image.ac_feed_share_sms()
                case .snapchat:
                    return R.image.ac_room_share_sn()
                case .copyLink:
                    return R.image.ac_feed_share_copy()
                case .shareLink:
                    return R.image.icon_social_share_link()
                case .more:
                    return R.image.ac_feed_share_more()
                }
            }
            
            var title: String {
                switch self {
                case .message:
                    return R.string.localizable.feedShareMessage()
                case .sms:
                    return R.string.localizable.socialSms()
                case .snapchat:
                    return "Snapchat"
                case .copyLink:
                    return R.string.localizable.socialCopyLink()
                case .shareLink:
                    return R.string.localizable.socialShareLink()
                case .more:
                    return R.string.localizable.feedShareMore()
                }
            }
        }
        
        private lazy var shareSourcesView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 66, height: 75)
            layout.minimumLineSpacing = 0
            layout.minimumLineSpacing = 12
            layout.sectionInset = .zero
            layout.headerReferenceSize = CGSize(width: 11, height: 0)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(cellWithClass: SourceCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var shareSources: [ShareSource] = {
            
            if MFMessageComposeViewController.canSendText() {
                return [.message, .sms, .copyLink, .more]
            } else {
                return [.message, .copyLink, .more]
            }
            
        }()
        
        private let selectedSourceSubject = PublishSubject<ShareSource>()
        
        var selectedSourceObservable: Observable<ShareSource> {
            return selectedSourceSubject.asObservable()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(shareSourcesView)
            shareSourcesView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.height.equalTo(67)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // MARK: - UICollectionViewDataSource
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return shareSources.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withClass: SourceCell.self, for: indexPath)
            let source = shareSources[indexPath.item]
            cell.iconImageV.image = source.icon
            cell.titleLabel.text = source.title
            return cell
        }
        
        // MARK: - UICollectionViewDelegate
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            selectedSourceSubject.onNext(shareSources[indexPath.item])
        }
        
    }
}

extension Feed.ShareBar {
    
    class SourceCell: UICollectionViewCell {
        
        private(set) lazy var iconImageV = UIImageView()
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 14)
            lb.textColor = .white
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: iconImageV, titleLabel)
            iconImageV.snp.makeConstraints { (maker) in
                maker.top.centerX.equalToSuperview()
                maker.width.equalTo(iconImageV.snp.height)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(iconImageV.snp.bottom).offset(8)
                maker.centerX.bottom.equalToSuperview()
                maker.leading.greaterThanOrEqualToSuperview()
            }
        }
        
    }
    
}
