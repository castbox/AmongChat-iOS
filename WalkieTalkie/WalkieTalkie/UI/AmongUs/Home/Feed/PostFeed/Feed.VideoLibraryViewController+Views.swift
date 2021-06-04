//
//  Feed.VideoLibraryViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/25.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import Photos
import RxSwift

extension Feed.VideoLibraryViewController {
    
    class VideoCell: UICollectionViewCell {
        
        private lazy var imageView: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var selectedIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_feed_library_unselected())
            return i
        }()
        
        private lazy var durationLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = .white
            return l
        }()
        
        private lazy var unsupportedView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            let icon = UIImageView(image: R.image.ac_feed_library_unsupported())
            let label = UILabel()
            label.font = R.font.nunitoExtraBold(size: 12)
            label.textColor = .white
            label.text = R.string.localizable.feedLibraryVideoUnsupported()
            label.adjustsFontSizeToFitWidth = true
            
            let guide = UILayoutGuide()
            v.addLayoutGuide(guide)
            guide.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.leading.greaterThanOrEqualToSuperview()
            }
            
            v.addSubviews(views: icon, label)
            
            icon.snp.makeConstraints { (maker) in
                maker.top.centerX.equalTo(guide)
            }
            
            label.snp.makeConstraints { (maker) in
                maker.top.equalTo(icon.snp.bottom).offset(4)
                maker.leading.trailing.bottom.equalTo(guide)
            }
            v.isHidden = true
            return v
        }()
        
        private lazy var gradientMusk: CAGradientLayer = {
            let l = CAGradientLayer()
            l.colors = [UIColor(hex6: 0x000000, alpha: 0).cgColor, UIColor(hex6: 0x000000, alpha: 1).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0.5)
            l.endPoint = CGPoint(x: 0.5, y: 1)
            l.locations = [0, 1]
            l.opacity = 0.5
            return l
        }()
        
        private var imageDisposable: Disposable? = nil
        
        override var isSelected: Bool {
            didSet {
                selectedIcon.image = isSelected ? R.image.ac_feed_library_selected() : R.image.ac_feed_library_unselected()
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layoutIfNeeded()
            gradientMusk.frame = contentView.bounds
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            contentView.clipsToBounds = true
            contentView.layer.cornerRadius = 12
            
            contentView.addSubviews(views: imageView, unsupportedView, selectedIcon, durationLabel)
            
            contentView.layer.insertSublayer(gradientMusk, above: imageView.layer)
            
            imageView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            unsupportedView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            selectedIcon.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(7)
                maker.top.equalToSuperview().inset(4)
            }
            
            durationLabel.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(7)
                maker.leading.greaterThanOrEqualToSuperview().inset(7)
                maker.bottom.equalToSuperview().inset(4)
            }
            
        }
        
        func configCell(with asset: PHAsset, imageOb: Observable<UIImage?>) {
            
            imageDisposable?.dispose()
            imageDisposable = imageOb.subscribe(onNext: { [weak self] (image) in
                self?.imageView.image = image
            })
            durationLabel.text = asset.duration.timeFormat
            
            if asset.duration > 60 {
                selectedIcon.isHidden = true
                unsupportedView.isHidden = false
            } else {
                selectedIcon.isHidden = false
                unsupportedView.isHidden = true
            }
        }
        
    }
    
}

extension Feed.VideoLibraryViewController {
    
    class DurationTipHeader: UICollectionReusableView {
        
        private(set) lazy var icon: UIImageView = {
            let i = UIImageView(image: R.image.ac_feed_video_tip())
            return i
        }()
        
        private(set) lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.textColor = UIColor(hexString: "#FFFFFF")
            l.font = R.font.nunitoExtraBold(size: 16)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.feedPostTip()
            return l
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: icon, titleLabel)
            
            icon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(icon)
                maker.leading.equalTo(icon.snp.trailing).offset(8)
                maker.trailing.lessThanOrEqualToSuperview().offset(-Frame.horizontalBleedWidth)
            }
        }
        
    }
    
    
}
