//
//  FansGroupSelfItemCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FansGroupSelfItemCell: UITableViewCell {
    enum Action {
        case start
        case edit
    }
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var groupIconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var bgView: UIView!
    
    private var actionHandler: ((Action) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tagView.layer.borderColor = UIColor(hex6: 0x222222).cgColor
        bgView.backgroundColor = UIColor(hex6: 0x222222)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func editButtonAction(_ sender: Any) {
        actionHandler?(.edit)
    }
    
    @IBAction func startLiveButtonAction(_ sender: Any) {
        actionHandler?(.start)
    }
    
    func bindData(_ group: Entity.Group, actionHandler: ((Action) -> Void)? = nil) {
        titleLabel.text = group.name
        groupIconView.setImage(with: group.cover.url)
        self.actionHandler = actionHandler
    }

}
