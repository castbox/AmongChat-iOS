//
//  AmongChat.CreateRoom.TopicCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.CreateRoom {
    
    class TopicCell: UITableViewCell {
        
        private lazy var icon: UIImageView = {
            let i = UIImageView()
            return i
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFF000")
            lb.font = R.font.nunitoExtraBold(size: 30)
            return lb
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            selectionStyle = .none
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: icon, titleLabel)
            
            icon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(40)
                maker.width.height.equalTo(30)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(icon.snp.right).offset(8)
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().inset(40)
            }
        }
        
        func bindViewModel(_ viewModel: TopicViewModel) {
            icon.image = viewModel.icon
            titleLabel.text = viewModel.name
        }
    }
    
}
