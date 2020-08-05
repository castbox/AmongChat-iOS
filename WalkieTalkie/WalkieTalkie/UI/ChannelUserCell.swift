//
//  ChannelUserCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/8/3.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class ChannelUserCell: UITableViewCell {

    @IBOutlet weak var micView: UIImageView!
    @IBOutlet weak var userAvatar: UIImageView!
    
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var statuLabel: UILabel!
    @IBOutlet weak var prefixLabel: UILabel!
    
    @IBOutlet weak var blockButton: UIButton!
    var tapBlockHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func bind(_ user: ChannelUser) {
        userAvatar.backgroundColor = user.iconColor.color()
        uidLabel.text = user.name
        statuLabel.text = user.status.title
        statuLabel.textColor = user.status.textColor
        micView.image = user.status.micImage
        prefixLabel.text = user.prefix
    }
    
    @IBAction func blockButtonAction(_ sender: Any) {
        tapBlockHandler?()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
