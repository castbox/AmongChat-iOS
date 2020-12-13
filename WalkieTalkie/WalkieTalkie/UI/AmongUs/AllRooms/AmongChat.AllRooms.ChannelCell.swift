//
//  AmongChat.AllRooms.ChannelCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/13.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.AllRooms {
    
    class ChannelCell: UICollectionViewCell {
        
        private lazy var tagIcon: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 15
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var hashSymbol: UILabel = {
            let lb = UILabel()
            lb.font = R.font.blackOpsOneRegular(size: 20)
            lb.textColor = UIColor.white.alpha(0.5)
            lb.text = "#"
            return lb
        }()
        
        private lazy var tagNameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 18)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var gradientLayer: CAGradientLayer = {
            let startColor = UIColor(hex6: 0x262626, alpha: 1)
            let endColor = UIColor(hex6: 0x111111, alpha: 0.8)
            let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
            let l = CAGradientLayer()
            l.colors = gradientColors
            l.locations = [NSNumber(floatLiteral: 0), NSNumber(floatLiteral: 1),]
            l.startPoint = CGPoint(x: 0, y: 0.5)
            l.endPoint = CGPoint(x: 1, y: 0.5)
            l.cornerRadius = 15
            return l
        }()
                
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            gradientLayer.frame = contentView.bounds
        }
                
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.addSubviews(views: hashSymbol, tagIcon, tagNameLabel)
            
            hashSymbol.snp.makeConstraints { (maker) in
                maker.center.equalTo(tagIcon)
            }
            
            tagIcon.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 40, height: 40))
                maker.centerY.equalToSuperview()
                maker.left.equalTo(10)
            }
            
            tagNameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(tagIcon.snp.right).offset(10)
                maker.centerY.equalToSuperview()
                maker.right.lessThanOrEqualToSuperview().offset(-10)
            }
            
            contentView.layer.insertSublayer(gradientLayer, at: 0)
        }
        
    }
    
}

extension AmongChat.AllRooms.ChannelCell {
    
    func configCell(with tag: AmongChat.Home.HashTag) {
        tagNameLabel.text = tag.name
        tagIcon.image = tag.icon
        hashSymbol.isHidden = (tag.icon != nil)
    }
    
}

extension AmongChat.AllRooms {
    
    class MoreCell: UICollectionViewCell {
                
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 18)
            lb.textColor = .white
            lb.text = R.string.localizable.amongChatAllRoomsMore()
            return lb
        }()
        
        private lazy var gradientLayer: CAGradientLayer = {
            let startColor = UIColor(hex6: 0x262626, alpha: 1)
            let endColor = UIColor(hex6: 0x111111, alpha: 0.8)
            let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
            let l = CAGradientLayer()
            l.colors = gradientColors
            l.locations = [NSNumber(floatLiteral: 0), NSNumber(floatLiteral: 1),]
            l.startPoint = CGPoint(x: 0, y: 0.5)
            l.endPoint = CGPoint(x: 1, y: 0.5)
            l.cornerRadius = 15
            return l
        }()
                
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            gradientLayer.frame = contentView.bounds
        }
                
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.addSubviews(views: titleLabel)
                        
            titleLabel.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(20)
                maker.centerY.equalToSuperview()
                maker.right.lessThanOrEqualToSuperview().offset(-10)
            }
            
            contentView.layer.insertSublayer(gradientLayer, at: 0)
        }
        
    }

    
}
