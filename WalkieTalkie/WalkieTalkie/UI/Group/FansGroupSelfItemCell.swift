//
//  FansGroupSelfItemCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FansGroupSelfItemCell: UITableViewCell {
    @IBOutlet weak var opContainer: UIStackView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var groupIconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
