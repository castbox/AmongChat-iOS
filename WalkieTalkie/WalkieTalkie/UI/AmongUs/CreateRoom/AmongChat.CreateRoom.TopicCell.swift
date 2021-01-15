//
//  AmongChat.CreateRoom.TopicCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.CreateRoom {
    
    class TopicCell: UICollectionViewCell {
        
        private lazy var coverIV: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var gradientMusk: CAGradientLayer = {
            let l = CAGradientLayer()
            l.colors = [UIColor(hex6: 0x000000, alpha: 0).cgColor, UIColor(hex6: 0x000000, alpha: 0.16).cgColor, UIColor(hex6: 0x000000, alpha: 1).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0.54)
            l.endPoint = CGPoint(x: 1.22, y: 1.22)
            l.locations = [0, 0.2, 1]
            l.cornerRadius = 12
            return l
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFFFFF")
            lb.font = R.font.bungeeRegular(size: 20)
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var checkIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_avatar_selected())
            i.isHidden = true
            return i
        }()
        
        override var isSelected: Bool {
            didSet {
                if isSelected {
                    checkIcon.isHidden = false
                    contentView.layer.borderWidth = 4
                    contentView.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
                } else {
                    checkIcon.isHidden = true
                    contentView.layer.borderWidth = 0
                    contentView.layer.borderColor = nil
                }
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layoutIfNeeded()
            gradientMusk.frame = contentView.bounds
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.layer.cornerRadius = 12
            contentView.clipsToBounds = true
            
            contentView.addSubviews(views: coverIV, checkIcon, titleLabel)
            
            contentView.layer.insertSublayer(gradientMusk, above: coverIV.layer)
            
            coverIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview().inset(12)
            }
            
            checkIcon.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview()
            }
        }
        
        func bindViewModel(_ viewModel: TopicViewModel) {
            titleLabel.text = viewModel.name
            coverIV.setImage(with: viewModel.coverUrl?.url)
        }
    }
    
}
