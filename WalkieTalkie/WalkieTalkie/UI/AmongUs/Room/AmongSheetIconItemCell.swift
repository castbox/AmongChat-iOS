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
            case .profile:
                button.setTitleColor(.white, for: .normal)
                button.setImage(R.image.ac_room_profile_icon(), for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.profileProfile(), for: .normal)
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
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setImage(R.image.ac_icon_sheet_report(), for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.reportTitle(), for: .normal)
            case .kick:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setImage(R.image.ac_icon_sheet_kick(), for: .normal)
                button.setBackgroundImage("333333".color().image, for: .normal)
                button.setTitle(R.string.localizable.amongChatRoomKick(), for: .normal)
            case .cancel:
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
    
    func setProfileUI() {
        button.setTitleColor(.white, for: .normal)
        switch item {
        case .block:
            button.setImage(R.image.ac_profile_block_icon(), for: .normal)
        case .unblock:
            button.setImage(R.image.ac_profile_unblock_icon(), for: .normal)
        case .report:
            button.setImage(R.image.ac_profile_report(), for: .normal)
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
