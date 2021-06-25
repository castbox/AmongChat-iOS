//
//  Feed.Share.SelectFriendsViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import MYTableViewIndex

extension Feed.Share.SelectFriendsViewController {
    
    class UserCell: UITableViewCell {
        
        private lazy var selectedIcon: UIImageView = {
            let iv = UIImageView(image: R.image.iconReportNormal())
            return iv
        }()
        
        private lazy var avatarIV: AvatarImageView = {
            let iv = AvatarImageView()
            iv.layer.cornerRadius = 24
            return iv
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.lineBreakMode = .byTruncatingMiddle
            return lb
        }()
        
        private lazy var textLayout = UILayoutGuide()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            selectionStyle = .none
            backgroundColor = .clear
            
            contentView.addSubviews(views: selectedIcon, avatarIV, nameLabel)
            
            selectedIcon.snp.makeConstraints { maker in
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(24)
                maker.leading.equalToSuperview().offset(20)
            }
            
            avatarIV.snp.makeConstraints { maker in
                maker.leading.equalTo(selectedIcon.snp.trailing).offset(12)
                maker.width.height.equalTo(48)
                maker.centerY.equalToSuperview()
            }
            
            contentView.addLayoutGuide(textLayout)
            
            nameLabel.snp.makeConstraints { maker in
                maker.edges.equalTo(textLayout)
                maker.height.equalTo(27)
            }
            
            textLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(avatarIV.snp.trailing).offset(12)
                maker.trailing.equalToSuperview().offset(-60)
            }
        }
        
        func bindData(_ user: UserViewModel, selected: Bool) {
            
            selectedIcon.image = selected ? R.image.iconReportSelected() : R.image.iconReportNormal()
            avatarIV.updateAvatar(with: user.user)
            avatarIV.setVerifyIcon(style: .gray)
            nameLabel.attributedText = user.user.nameWithVerified(fontSize: 27, withAge: false, isShowVerify: false, isShowOfficial: true, officialHeight: ._18)
        }
        
    }
    
}

extension Feed.Share.SelectFriendsViewController {
    
    class IconHeader: UIView {
        
        private(set) lazy var icon: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor(hex6: 0x898989)
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = UIColor(hex6: 0x121212)
            addSubviews(views: icon, titleLabel)
            
            icon.snp.makeConstraints { maker in
                maker.leading.equalToSuperview().offset(20)
                maker.width.height.equalTo(24)
                maker.centerY.equalTo(titleLabel)
            }
            
            titleLabel.snp.makeConstraints { maker in
                maker.leading.equalTo(icon.snp.trailing).offset(8)
                maker.trailing.equalToSuperview().offset(-60)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(27)
            }
            
        }
        
    }
    
    class IndexHeader: UIView {
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = UIColor(hex6: 0x898989)
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = UIColor(hex6: 0x121212)
            addSubviews(views: titleLabel)
            
            titleLabel.snp.makeConstraints { maker in
                maker.leading.equalToSuperview().offset(20)
                maker.trailing.equalToSuperview().offset(-60)
                maker.bottom.equalToSuperview()
                maker.height.equalTo(22)
            }
            
        }
        
    }
    
}

extension Feed.Share.SelectFriendsViewController {
    
    class TableIndexLabel: StringItem {
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: 20, height: 20)
        }
        
    }
    
    class TableIndexImage: ImageItem {
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            return CGSize(width: 20, height: 20)
        }
    }
}
