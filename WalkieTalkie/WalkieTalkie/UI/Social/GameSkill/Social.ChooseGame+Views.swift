//
//  Social.ChooseGame+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/23.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Social.ChooseGame {
    
    class GameCell: AmongChat.CreateRoom.TopicCell {
        
        private lazy var addedView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.7)
            
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFFFFF")
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.amongChatAdded()
            
            let i = UIImageView(image: R.image.ac_choose_game_added())
            
            let l = UILayoutGuide()
            
            v.addLayoutGuide(l)
            l.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.leading.greaterThanOrEqualTo(12)
            }
            
            v.addSubviews(views: i, lb)
            
            i.snp.makeConstraints { (maker) in
                maker.top.centerX.equalTo(l)
                maker.width.height.equalTo(36)
            }
            
            lb.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalTo(l)
                maker.height.equalTo(22)
                maker.top.equalTo(i.snp.bottom).offset(8)
            }
            v.isHidden = true
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        private func setupLayout() {
            contentView.addSubviews(views: addedView)
            addedView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
        func bindViewModel(_ viewModel: Social.ChooseGame.GameViewModel) {
            titleLabel.text = viewModel.name
            coverIV.setImage(with: viewModel.coverUrl?.url)
            addedView.isHidden = !viewModel.skill.isAdd
        }
        
    }
    
}

extension Social.ChooseGame {
    
    static func bottomGradientView() -> GradientView{
        let v = GradientView()
        let l = v.layer
        l.colors = [UIColor(hex6: 0x191919, alpha: 0).cgColor, UIColor(hex6: 0x1D1D1D, alpha: 0.18).cgColor, UIColor(hex6: 0x232323, alpha: 0.57).cgColor, UIColor(hex6: 0x121212).cgColor]
        l.startPoint = CGPoint(x: 0.5, y: 0)
        l.endPoint = CGPoint(x: 0.5, y: 0.41)
        l.locations = [0, 0.3, 0.6, 1]
        return v
    }
    
}
