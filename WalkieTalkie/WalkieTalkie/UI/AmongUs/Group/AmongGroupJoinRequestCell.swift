//
//  AmongGroupJoinRequestCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AmongGroupJoinRequestCell: UITableViewCell {
    private lazy var userView: AmongChat.Home.UserView = {
        let v = AmongChat.Home.UserView()
        return v
    }()
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubview()
        bindSubviewEvent()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bindSubviewEvent() {
        
    }
    
    func configureSubview() {
        contentView.backgroundColor = .clear
        
        contentView.addSubviews(views: userView)
        
//        let buttonLayout = UILayoutGuide()
//        contentView.addLayoutGuide(buttonLayout)
//        buttonLayout.snp.makeConstraints { (maker) in
//            maker.centerY.equalToSuperview()
//            maker.trailing.equalToSuperview().inset(20)
//            maker.height.equalTo(32)
//        }
        
        userView.snp.makeConstraints { (maker) in
            maker.leading.top.equalToSuperview().offset(20)
            maker.trailing.equalTo(-20)
        }
    }
    
}
