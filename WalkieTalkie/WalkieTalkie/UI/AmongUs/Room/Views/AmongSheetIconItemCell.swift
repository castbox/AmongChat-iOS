//
//  AmongSheetIconItemCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 18/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongSheetIconItemCell: UITableViewCell {

    @IBOutlet weak var button: UIButton!
    
    var item: AmongSheetController.ItemType = .cancel {
        didSet {
            button.setTitleColor(item.titleColor, for: .normal)
            button.setBackgroundImage(item.backgroundImage, for: .normal)//333333
            button.setTitle(item.title, for: .normal)
        }
    }
    
    var clickHandler: ((AmongSheetController.ItemType) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor(hex6: 0x1D1D1D)
    }
    
    func setProfileUI() {
        switch item {
        case .block, .unblock, .report:
            button.setTitleColor(.white, for: .normal)
        default:
            break
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        clickHandler?(item)
    }
}
