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
    
    class AvatarView: UIView {
        
        var a_borderWidth: CGFloat = 0 {
            didSet {
                updateLayout()
            }
        }
        
        var a_borderColor: UIColor? = nil {
            didSet {
                updateLayout()
            }
        }
        
        var a_cornerRadius: CGFloat = 0 {
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
            
            border.layer.cornerRadius = a_borderWidth + a_cornerRadius
            border.layer.borderWidth = a_borderWidth
            border.layer.borderColor = a_borderColor?.cgColor
            
            iv.layer.cornerRadius = a_cornerRadius
        }
        
    }
    
}
