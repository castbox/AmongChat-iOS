//
//  ChannelUserCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/8/3.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

class ChannelUserCell: UITableViewCell {

    @IBOutlet weak var micView: UIImageView!
    @IBOutlet weak var userAvatar: UIImageView!
    
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var statuLabel: UILabel!
    @IBOutlet weak var prefixLabel: UILabel!
    
    @IBOutlet weak var blockButton: UIButton!
    var tapBlockHandler: (() -> Void)?
    
    private var avatarDisposable: Disposable?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func bind(_ userViewModel: ChannelUserViewModel) {
        let user = userViewModel.channelUser
        avatarDisposable?.dispose()
        avatarDisposable = userViewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
            guard let `self` = self else { return }
            
            if let _ = image {
                self.userAvatar.backgroundColor = .clear
            } else {
                self.userAvatar.backgroundColor = user.iconColor.color()
            }
            self.userAvatar.image = image            
        })
        
        uidLabel.text = userViewModel.name
        statuLabel.text = user.status.title
        statuLabel.textColor = user.status.textColor
        micView.image = user.status.micImage
        prefixLabel.text = user.prefix
        if user.status == .talking {
            statuLabel.font = R.font.nunitoBold(size: 14)
        } else {
            statuLabel.font = R.font.nunitoSemiBold(size: 14)
        }
        prefixLabel.isHidden = (userViewModel.firestoreUser != nil)
        blockButton.isHidden = userViewModel.isSelf
    }
    
    @IBAction func blockButtonAction(_ sender: Any) {
        tapBlockHandler?()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
