//
//  FansGroup.Views.ShareBar.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/10.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MessageUI

extension FansGroup.Views {
    
    class ShareBar: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
        
        enum ShareSource {
//            case message
            case sms
            case snapchat
            case copyLink
            case shareLink
            case tiktok
            
            var icon: UIImage? {
                switch self {
                case .sms:
                    return R.image.ac_room_share()
                case .snapchat:
                    return R.image.ac_room_share_sn()
                case .copyLink:
                    return R.image.ac_room_copylink()
                case .shareLink:
                    return R.image.icon_social_share_link()
                case .tiktok:
                    return R.image.icon_social_tiktok()
                }
            }
            
            var title: String {
                switch self {
                case .sms:
                    return R.string.localizable.socialSms()
                case .snapchat:
                    return "Snapchat"
                case .copyLink:
                    return R.string.localizable.socialCopyLink()
                case .shareLink:
                    return R.string.localizable.socialShareLink()
                case .tiktok:
                    return "TikTok"
                }
            }
            
            var stringValue: String {
                switch self {
                case .sms:
                    return "sms"
                case .snapchat:
                    return "snapchat"
                case .copyLink:
                    return "copy"
                case .shareLink:
                    return "sharelink"
                case .tiktok:
                    return "tiktok"
                }
            }
        }
        
        private lazy var shareSourcesView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 80, height: 67)
            layout.minimumLineSpacing = 0
            layout.sectionInset = .zero
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
                return [.sms, .snapchat, .tiktok, .copyLink, .shareLink]
            } else {
                return [.snapchat, .tiktok, .copyLink, .shareLink]
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

extension FansGroup.Views.ShareBar {
    
    class SourceCell: UICollectionViewCell {
        
        private(set) lazy var iconImageV = UIImageView()
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoBold(size: 14)
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
