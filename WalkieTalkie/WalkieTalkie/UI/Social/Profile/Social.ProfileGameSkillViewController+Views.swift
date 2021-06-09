//
//  Social.ProfileGameSkillViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/2.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension Social.ProfileGameSkillViewController {
    
    class GameCell: UICollectionViewCell {
        
        private let bag = DisposeBag()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFFFFF")
            lb.font = R.font.bungeeRegular(size: 20)
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private(set) lazy var deleteButton: SmallSizeButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setImage(R.image.ac_profile_delete_game_stats(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.deleteHandler?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var statsIV: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            i.clipsToBounds = true
            return i
        }()
        
        private lazy var gradientLayer: CAGradientLayer = {
            let l = CAGradientLayer()
            l.colors = [UIColor(hex6: 0x303030).cgColor, UIColor(hex6: 0x222222).cgColor]
            l.startPoint = CGPoint(x: 0, y: 0)
            l.endPoint = CGPoint(x: 1, y: 0)
            return l
        }()
        
        var deleteHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            
            let container = UIView()
            container.backgroundColor = .clear
            container.layer.addSublayer(gradientLayer)
            
            container.addSubviews(views: nameLabel, deleteButton, statsIV)
            contentView.addSubview(container)
            
            container.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            container.layer.cornerRadius = 12
            container.layer.masksToBounds = true
            
            let titleLayout = UILayoutGuide()
            container.addLayoutGuide(titleLayout)
            titleLayout.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                var height: CGFloat = 44
                adaptToIPad {
                    height = 48
                }
                maker.height.equalTo(height)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(16)
                maker.centerY.equalTo(titleLayout)
                maker.height.equalTo(20)
                maker.trailing.lessThanOrEqualTo(deleteButton.snp.leading).offset(-23)
            }
            
            deleteButton.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(20)
                maker.centerY.equalTo(titleLayout)
                maker.trailing.equalTo(-12)
            }
            
            statsIV.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.top.equalTo(titleLayout.snp.bottom)
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layoutIfNeeded()
            gradientLayer.frame = contentView.bounds
        }
        
        func bind(_ game: Entity.UserGameSkill) {
            nameLabel.text = game.topicName.uppercased()
            statsIV.setImage(with: game.img)
        }
    }
    
}
