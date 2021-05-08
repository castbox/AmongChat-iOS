//
//  ConversationCollectionCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

protocol ConversationCellGeometory {
        
    static func cellSize(for notice: Entity.Notice) -> CGSize
}


extension ConversationCellGeometory {
    
    static var cellWidth: CGFloat {
        let hInset: CGFloat = 20
        let columns: Int = 1
        let interitemSpacing: CGFloat = 20
        let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
        return cellWidth
    }
    
}

class ConversationCollectionCell: UICollectionViewCell, ConversationCellGeometory {
    
    private static let titleHeight:CGFloat = 27
    private static let textLeading: CGFloat = 12
    private static let messageTopPadding: CGFloat = 1
    private static let textFont = R.font.nunitoBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold)
    private static let imageViewSize = CGSize(width: 48, height: 48)
    private static let timeLableTopPadding: CGFloat = 4
    private static let timeLableHeight: CGFloat = 19
    
    static func cellSize(for notice: Entity.Notice) -> CGSize {

        let txtHeight = notice.message.text?.height(forConstrainedWidth: cellWidth - imageViewSize.width - textLeading, font: Self.textFont) ?? 0
        
        let height = ceil(titleHeight + messageTopPadding + txtHeight + timeLableTopPadding + timeLableHeight)
        return CGSize(width: cellWidth, height: max(height, imageViewSize.height))
    }
    
    private lazy var container: UIView = {
        let i = UIView()
        i.clipsToBounds = true
        i.addSubviews(views: avatarImageView, textContainer)
        return i
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let i = UIImageView(frame: CGRect(x: 20, y: 0, width: 32, height: 32))
        i.clipsToBounds = true
        i.contentMode = .scaleAspectFill
        return i
    }()
    
    private lazy var textContainer: UIImageView = {
        let i = UIImageView(frame: CGRect(x: 60, y: 0, width: Frame.Screen.width - 60 * 2, height: 109))
        i.clipsToBounds = true
        i.contentMode = .scaleAspectFill
        i.backgroundColor = .red
        i.addSubview(messageTextLabel)
        
        messageTextLabel.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(12)
        }
        return i
    }()
    
//    private lazy var messageTitleLabel: UILabel = {
//        let l = UILabel()
//        l.font = R.font.nunitoExtraBold(size: 20)
//        l.textColor = UIColor(hex6: 0xFFFFFF)
//        return l
//    }()
    
    private lazy var messageTextLabel: UILabel = {
        let l = UILabel()
        l.font = R.font.nunitoBold(size: 14)
        l.textColor = UIColor(hex6: 0xFFFFFF)
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        return l
    }()
    
    private lazy var timeLabel: UILabel = {
        let l = UILabel()
        l.font = R.font.nunitoBold(size: 14)
        l.textColor = UIColor(hex6: 0x595959)
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpLayout() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubviews(views: avatarImageView, textContainer, timeLabel)
        
//        avatarImageView.snp.makeConstraints { (maker) in
//            maker.top.leading.equalToSuperview()
//            maker.size.equalTo(Self.imageViewSize)
//        }
//
//        textContainer.snp.makeConstraints { (maker) in
//            maker.top.equalTo(avatarImageView)
//            maker.leading.equalTo(avatarImageView.snp.trailing).offset(Self.textLeading)
//            maker.trailing.equalToSuperview()
//            maker.height.equalTo(Self.titleHeight)
//        }
//
//        messageTextLabel.snp.makeConstraints { (maker) in
//            maker.leading.trailing.equalTo(messageTitleLabel)
//            maker.top.equalTo(messageTitleLabel.snp.bottom).offset(Self.messageTopPadding)
//        }
//
//        timeLabel.snp.makeConstraints { (maker) in
//            maker.leading.trailing.equalTo(messageTitleLabel)
//            maker.height.equalTo(Self.timeLableHeight)
//            maker.top.equalTo(messageTextLabel.snp.bottom).offset(Self.timeLableTopPadding)
//            maker.bottom.equalToSuperview()
//        }
        
    }
    
    func bindNoticeData(_ noticeVM: Notice.NoticeViewModel) {
        let notice = noticeVM.notice
        
        let imagePlaceholder: UIImage?
        messageTextLabel.text = notice.message.text
        timeLabel.text = noticeVM.timeString
        
        switch notice.message.messageObjType {
        case .group, .room, .unknown:
            avatarImageView.layer.cornerRadius = 8
            imagePlaceholder = nil
        case .user:
            avatarImageView.layer.cornerRadius = Self.imageViewSize.height / 2
            imagePlaceholder = R.image.ac_profile_avatar()
        }
        avatarImageView.setImage(with: notice.message.img, placeholder: imagePlaceholder)
        
    }

}
