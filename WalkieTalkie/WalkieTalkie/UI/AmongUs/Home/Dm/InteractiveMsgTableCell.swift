//
//  InteractiveMsgTableCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class InteractiveMsgTableCell: UITableViewCell {

    @IBOutlet weak var avatarView: AvatarImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var postCoverView: UIImageView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var redDotView: UIView!
    @IBOutlet weak var emoteView: UIImageView!
    
    private var viewModel: Conversation.InteractiveMessageCellViewModel?
    private let bag = DisposeBag()
    
    func configView(with viewModel: Conversation.InteractiveMessageCellViewModel) {
        self.viewModel = viewModel
        let msg = viewModel.msg
        avatarView.setAvatarImage(with: msg.pictureUrl)
        avatarView.isVerify = msg.isVerified
        nameLabel.attributedText = msg.nameWithVerified()
        desLabel.text = msg.opType?.title
        postCoverView.setImage(with: msg.img)
        timeLabel.text = viewModel.timeString
        commentLabel.text = msg.text
        emoteView.setImage(with: viewModel.emote, placeholder: nil)
        emoteView.isHidden = msg.opType != .emotes
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        avatarView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let uid = self?.viewModel?.msg.uid else {
                    return
                }
                Routes.handle("/profile/\(uid)")
            })
            .disposed(by: bag)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
