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
            switch item {
            case .block:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setImage(R.image.ac_icon_sheet_block(), for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.alertBlock(), for: .normal)
            case .unblock:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setImage(R.image.ac_icon_sheet_unblock(), for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.alertUnblock(), for: .normal)
            case .mute:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setImage(R.image.ac_icon_sheet_mute(), for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.channelUserListMute(), for: .normal)

            case .unmute:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setImage(R.image.ac_icon_sheet_unmute(), for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.channelUserListUnmute(), for: .normal)
            case .report:
                button.setTitleColor(.white, for: .normal)
                button.setImage(nil, for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.reportTitle(), for: .normal)
            case .cancel, .kick:
                button.setTitleColor(.white, for: .normal)
                button.setImage(nil, for: .normal)
                button.setBackgroundImage(nil, for: .normal)
                button.setTitle(R.string.localizable.toastCancel(), for: .normal)
            case .userInfo:
                ()
            }
        }
    }
    
    var clickHandler: ((AmongSheetController.ItemType) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        clickHandler?(item)
    }
}
