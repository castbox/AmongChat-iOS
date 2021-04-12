//
//  FansGroupItemCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FansGroupItemCell: UITableViewCell {

    @IBOutlet weak var groupAvatarView: UIImageView!
    @IBOutlet weak var groupTitleLabel: UILabel!
    @IBOutlet weak var groupIntroLabel: UILabel!    
    
    @IBOutlet weak var groupInfoContainer: UIView!
    @IBOutlet weak var topicIconView: UIImageView!
    @IBOutlet weak var topicNameLabel: UILabel!
    @IBOutlet weak var groupUserCountLabel: UILabel!
    @IBOutlet weak var topicContainer: UIView!
    @IBOutlet weak var onlineTagView: UIView!
    
    private(set) lazy var topicView: FansGroup.Views.GroupTopicView = {
        let v = FansGroup.Views.GroupTopicView()
        return v
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        topicContainer.addSubview(topicView)
        topicView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bindData(_ group: Entity.Group) {
        
        groupAvatarView.setImage(with: group.cover.url)
        groupTitleLabel.text = group.name
        groupIntroLabel.text = group.description
        groupUserCountLabel.text = "\(group.membersCount)"
        topicView.coverSourceRelay.accept(group.coverURL)
        topicView.nameRelay.accept(group.topicName)
        groupInfoContainer.isHidden = false
        onlineTagView.isHidden = group.status == 0
        
    }
    
}
