//
//  AmongGroupJoinRequestCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AmongGroupJoinRequestCell: UITableViewCell {
    enum Action {
        case accept
        case reject
    }
    
    private lazy var userView: AmongChat.Home.UserView = {
        let v = AmongChat.Home.UserView()
        return v
    }()
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var actionHandler: ((Action) -> Void)?
    
    var profile: Entity.UserProfile? {
        didSet {
            guard let profile = profile else {
                return
            }
            userView.bind(viewModel: profile) {
                
            }
        }
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubview()
        bindSubviewEvent()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubview()
        bindSubviewEvent()
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
//        contentView.backgroundColor = .clear
        
        contentView.addSubviews(views: userView)

        userView.snp.makeConstraints { (maker) in
            maker.leading.top.equalToSuperview().offset(20)
            maker.trailing.equalTo(-20)
            maker.height.equalTo(40)
        }
    }
    
}
