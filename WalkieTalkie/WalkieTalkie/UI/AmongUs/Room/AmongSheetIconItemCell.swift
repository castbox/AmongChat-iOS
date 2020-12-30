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
                button.setBackgroundImage("3D3D3D".color().image, for: .normal)//333333
                button.setTitle(R.string.localizable.profileProfile(), for: .normal)
            case .block:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setBackgroundImage("3D3D3D".color().image, for: .normal)
                button.setTitle(R.string.localizable.alertBlock(), for: .normal)
            case .unblock:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setBackgroundImage("3D3D3D".color().image, for: .normal)
                button.setTitle(R.string.localizable.alertUnblock(), for: .normal)
            case .mute:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setBackgroundImage("3D3D3D".color().image, for: .normal)
                button.setTitle(R.string.localizable.channelUserListMute(), for: .normal)

            case .unmute:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setBackgroundImage("3D3D3D".color().image, for: .normal)
                button.setTitle(R.string.localizable.channelUserListUnmute(), for: .normal)
            case .report:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setBackgroundImage("3D3D3D".color().image, for: .normal)
                button.setTitle(R.string.localizable.reportTitle(), for: .normal)
            case .kick:
                button.setTitleColor("FB5858".color(), for: .normal)
                button.setBackgroundImage("3D3D3D".color().image, for: .normal)
                button.setTitle(R.string.localizable.amongChatRoomKick(), for: .normal)
            case .cancel:
                button.setTitleColor("898989".color(), for: .normal)
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
