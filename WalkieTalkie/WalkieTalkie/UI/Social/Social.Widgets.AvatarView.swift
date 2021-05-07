//
//  Social.Widgets.AvatarView.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/8.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    struct Widgets {}
}

extension Social.Widgets {
    
    class OuterBorderdImageView: UIView {
        
        var a_borderWidth: CGFloat = 0 {
            didSet {
                updateLayout()
            }
        }
        
        var a_borderColor: UIColor? = .clear {
            didSet {
                updateLayout()
            }
        }
        
        var a_cornerRadius: CGFloat = 0 {
            didSet {
                updateLayout()
            }
        }
        
        var a_backgroundColor: UIColor? = .clear {
            didSet {
                updateLayout()
            }
        }
        
        var image: UIImage? = nil {
            didSet {
                iv.image = image
            }
        }
        
        private lazy var iv: UIImageView = {
            let iv = UIImageView()
            iv.clipsToBounds = true
            return iv
        }()
        
        private lazy var border: UIView = {
            let v = UIView()
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: border, iv)
            
            iv.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            border.snp.makeConstraints { (maker) in
                maker.edges.equalTo(iv).inset(0)
            }
        }
        
        private func updateLayout() {
            
            border.snp.updateConstraints { (maker) in
                maker.edges.equalTo(iv).inset(-a_borderWidth)
            }
            
            let overlap: CGFloat = 1
            
            border.layer.cornerRadius = a_borderWidth + a_cornerRadius
            border.layer.borderWidth = a_borderWidth + overlap
            border.layer.borderColor = a_borderColor?.cgColor
            
            iv.layer.cornerRadius = a_cornerRadius
            iv.backgroundColor = a_backgroundColor
        }
        
        func setImage(with url: String?) {
            iv.setImage(with: url)
        }
        
    }
    
}

extension Social.Widgets {
    
    class OnlineStatusView: UIView {
        
        private lazy var icon: UIImageView = {
            let i = UIImageView(image: R.image.online())
            return i
        }()
        
        private lazy var label: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            l.text = R.string.localizable.socialStatusOnline()
            return l
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
            layer.cornerRadius = bounds.height / 2
        }
        
        private func setUpLayout() {
            
            backgroundColor = UIColor(hex6: 0x222222)
            clipsToBounds = true
            
            let layout = UILayoutGuide()
            addLayoutGuide(layout)
            layout.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.height.equalTo(24)
            }
            
            addSubviews(views: icon, label)
            icon.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(16)
                maker.leading.equalToSuperview().offset(8)
                maker.centerY.equalToSuperview()
            }
            
            label.snp.makeConstraints { (maker) in
                maker.leading.equalTo(icon.snp.trailing).offset(2)
                maker.trailing.equalToSuperview().offset(-8)
                maker.centerY.equalToSuperview()
            }
        }
    }
    
}
