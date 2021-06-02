//
//  Social.ProfileGroupsViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/2.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension Social.ProfileGroupsViewController {
    
    class JoinedGroupCell: UICollectionViewCell {
        
        private let bag = DisposeBag()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFFFFF")
            lb.font = R.font.nunitoExtraBold(size: 14)
            return lb
        }()
        
        private lazy var coverIV: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var gradientMusk: CAGradientLayer = {
            let l = CAGradientLayer()
            l.colors = [UIColor(hex6: 0x000000, alpha: 0).cgColor, UIColor(hex6: 0x000000, alpha: 0.16).cgColor, UIColor(hex6: 0x000000, alpha: 1).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0.5)
            l.endPoint = CGPoint(x: 0.5, y: 1.22)
            l.locations = [0, 0.2, 1]
            l.cornerRadius = 12
            l.opacity = 0.6
            return l
        }()
        
        private lazy var onlineStatusView: FansGroup.Views.GroupCellTagView = {
            let v = FansGroup.Views.GroupCellTagView(.online)
            v.layer.borderColor = UIColor(hex6: 0x121212).cgColor
            return v
        }()
        
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
            
            contentView.addSubviews(views: coverIV, nameLabel, onlineStatusView)
            
            contentView.layer.insertSublayer(gradientMusk, above: coverIV.layer)
            
            coverIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(7)
                maker.bottom.equalTo(-4)
            }
            
            onlineStatusView.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().offset(2.5)
                maker.top.equalTo(-10)
            }
            
        }
        
        func bindData(_ group: Entity.Group) {
            coverIV.setImage(with: group.cover.url)
            nameLabel.text = group.name
            #if DEBUG
            onlineStatusView.isHidden = false
            #else
            onlineStatusView.isHidden = group.status == 0
            #endif
        }
        
    }
    
}
