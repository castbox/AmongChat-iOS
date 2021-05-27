//
//  Social.ProfileViewcontrollerExtension.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SwiftyUserDefaults

extension Social.ProfileViewController {
    
    class ProfileTableCell: UICollectionViewCell {
        
        private lazy var leftIconIV: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var rightIconIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_right_arrow())
            return i
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configCell(with option: Option) {
            leftIconIV.image = option.image()
            titleLabel.text = option.text()
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            contentView.layer.cornerRadius = 12
            contentView.backgroundColor = UIColor(hex6: 0x222222)

            contentView.addSubviews(views: leftIconIV, titleLabel, rightIconIV)
            
            leftIconIV.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(40)
                maker.leading.equalTo(16)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(leftIconIV.snp.trailing).offset(12)
                maker.trailing.lessThanOrEqualTo(rightIconIV.snp.leading).offset(-8)
            }
            
            rightIconIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(20)
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(16)
            }
            
        }
    }
    
}

extension Social.ProfileViewController {
    
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

extension Social.ProfileViewController {
    
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

extension Social.ProfileViewController {
    
    class SectionHeader: UICollectionReusableView {
        
        private(set) lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.textColor = UIColor(hexString: "#FFFFFF")
            l.font = R.font.nunitoExtraBold(size: 20)
            l.adjustsFontSizeToFitWidth = true
            return l
        }()
        
        private(set) lazy var actionButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.actionHandler?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private let bag = DisposeBag()
        
        var actionHandler: (() -> Void)? = nil
                
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: titleLabel, actionButton)
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.centerY.equalToSuperview()
                maker.height.equalTo(27)
                maker.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-20)
            }
            
            actionButton.snp.makeConstraints { maker in
                maker.centerY.trailing.equalToSuperview()
                maker.height.equalTo(27)
            }
        }
        
    }
    
    class SectionFooter: UICollectionReusableView {
        override init(frame: CGRect) {
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
}

extension Social.ProfileViewController {
    
    class LiveCell: UICollectionViewCell {
        
        private let bag = DisposeBag()
        
        private(set) lazy var coverIV: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private(set) lazy var label: UILabel = {
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFFFFF")
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private(set) lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.setBackgroundImage(UIColor(hex6: 0xFFF000).image, for: .normal)
            btn.setBackgroundImage(UIColor.clear.image, for: .disabled)
            btn.setTitle(R.string.localizable.socialJoinAction().uppercased(), for: .normal)
            btn.setTitle("", for: .disabled)
            btn.setImage(nil, for: .normal)
            btn.setImage(R.image.ac_home_friends_locked(), for: .disabled)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.joinHandler?()
                })
                .disposed(by: bag)

            return btn
        }()
        
        var joinHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = .clear
            contentView.layer.cornerRadius = 12
            contentView.backgroundColor = UIColor(hex6: 0x222222)

            contentView.addSubviews(views: coverIV, label, joinBtn)
            
            coverIV.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.width.equalTo(coverIV.snp.height)
            }
            
            label.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(coverIV.snp.trailing).offset(12)
                maker.trailing.equalTo(joinBtn.snp.leading).offset(-12)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().offset(-16)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(32)
            }
            
            joinBtn.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            joinBtn.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            label.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            label.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
        }
        
    }
    
}
