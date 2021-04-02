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
    @IBOutlet weak var opContainer: UIStackView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    
    @IBOutlet weak var groupInfoContainer: UIView!
    @IBOutlet weak var topicIconView: UIImageView!
    @IBOutlet weak var topicNameLabel: UILabel!
    @IBOutlet weak var groupUserCountLabel: UILabel!
    @IBOutlet weak var onlineTagView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
