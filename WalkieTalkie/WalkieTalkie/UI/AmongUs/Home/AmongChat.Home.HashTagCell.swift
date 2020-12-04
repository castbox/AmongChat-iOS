//
//  AmongChat.Room.HashTagCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/26.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class HashTagCell: UICollectionViewCell {
        
        private lazy var tagIcon: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 8
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
            lb.font = R.font.nunitoRegular(size: 14)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var gradientLayer: CAGradientLayer = {
            let startColor = UIColor(hex: 0x262626)!
            let endColor = UIColor(hex: 0x111111)!
            let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
            let l = CAGradientLayer()
            l.colors = gradientColors
            l.locations = [NSNumber(floatLiteral: 0), NSNumber(floatLiteral: 1),]
            l.startPoint = CGPoint(x: 0, y: 0.5)
            l.endPoint = CGPoint(x: 1, y: 0.5)
            l.cornerRadius = 11
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
                maker.size.equalTo(CGSize(width: 23, height: 23))
                maker.centerY.equalToSuperview()
                maker.left.equalTo(8)
            }
            
            tagNameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(tagIcon.snp.right).offset(8)
                maker.centerY.equalToSuperview()
                maker.right.lessThanOrEqualToSuperview().offset(-8)
            }
            
            contentView.layer.insertSublayer(gradientLayer, at: 0)
        }
                
    }
}

extension AmongChat.Home.HashTagCell {
    
    func configCell(with tag: AmongChat.Home.HashTag) {
        tagNameLabel.text = tag.name
        tagIcon.image = tag.icon
    }
    
}
