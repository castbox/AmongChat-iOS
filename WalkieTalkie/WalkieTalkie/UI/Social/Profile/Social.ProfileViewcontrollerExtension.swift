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
        
        private(set) lazy var leftIconIV: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private(set) lazy var rightIconIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_right_arrow())
            return i
        }()
        
        private(set) lazy var titleLabel: UILabel = {
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
            contentView.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.12)

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
