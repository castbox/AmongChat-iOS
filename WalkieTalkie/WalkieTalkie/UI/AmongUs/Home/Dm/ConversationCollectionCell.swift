//
//  ConversationCollectionCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

private let avatarLeftEdge: CGFloat = 20
private let contentLeftEdge: CGFloat = 60

class ConversationCollectionCell: UICollectionViewCell {
    
    enum Action {
        case resend(Entity.DMMessage)
    }
    
    private lazy var container: UIView = {
        let i = UIView(frame: CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 200))
        i.clipsToBounds = true
        i.addSubviews(views: avatarImageView, textContainer)
        return i
    }()
    
    private lazy var avatarImageView: UIImageView = {
        let i = UIImageView(frame: CGRect(x: 20, y: 0, width: 32, height: 32))
        i.cornerRadius = 16
        i.clipsToBounds = true
        i.contentMode = .scaleAspectFill
        return i
    }()
    
    private lazy var textContainer: UIImageView = {
        let i = UIImageView(frame: CGRect(x: 60, y: 0, width: Frame.Screen.width - 60 * 2, height: 109))
        i.clipsToBounds = true
        i.contentMode = .scaleAspectFill
        i.backgroundColor = "#222222".color()
        i.addSubview(messageTextLabel)
        i.roundCorners(topLeft: 2, topRight: 18, bottomLeft: 18, bottomRight: 18)
        
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
//        l.lineBreakMode = .byWordWrapping
        return l
    }()
    
    private lazy var timeLabel: UILabel = {
        let l = UILabel(frame: CGRect(x: 20, y: 0, width: Frame.Screen.width - 20 * 2, height: 19))
        l.font = R.font.nunitoBold(size: 14)
        l.textAlignment = .center
        l.textColor = UIColor(hex6: 0x595959)
        return l
    }()
    
    private lazy var statusView: UIButton = {
        let button = UIButton()
        button.size = CGSize(width: 24, height: 24)
        button.setImage(R.image.dmSendFailed(), for: .normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(statusViewAction), for: .primaryActionTriggered)
        return button
    }()
    
    private lazy var unreadView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 9, height: 9))
        v.cornerRadius = 4.5
        v.backgroundColor = "#FB5858".color()
        v.isHidden = true
        return v
    }()
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .white)
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()
    
    var viewModel: Conversation.MessageCellViewModel?
    
    var actionHandler: ((Action) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpLayout()
    }
    
    func bind(_ viewModel: Conversation.MessageCellViewModel) {
        self.viewModel = viewModel
        let msg = viewModel.message
        avatarImageView.setAvatarImage(with: msg.fromUser.pictureUrl)
        timeLabel.text = msg.dateString
        
        switch msg.body.msgType {
        case .text:
            messageTextLabel.text = msg.body.text
            textContainer.size = CGSize(width: viewModel.contentSize.width + 12 * 2, height: viewModel.contentSize.height + 12 * 2)
            messageTextLabel.size = viewModel.contentSize
            container.height = textContainer.size.height
            if viewModel.sendFromMe {
                //avatar
                avatarImageView.right = Frame.Screen.width - avatarLeftEdge
                textContainer.right = Frame.Screen.width - contentLeftEdge
                textContainer.roundCorners(topLeft: 18, topRight: 2, bottomLeft: 18, bottomRight: 18)
                statusView.right = textContainer.left - 8
            } else {
                avatarImageView.left = avatarLeftEdge
                textContainer.left = contentLeftEdge
                textContainer.roundCorners(topLeft: 2, topRight: 18, bottomLeft: 18, bottomRight: 18)
                statusView.left = textContainer.right + 8
            }
            statusView.centerY = textContainer.centerY
            indicatorView.center = statusView.center
        case .gif:
            ()
        case .voice:
            ()
        case .none:
            ()
        }
        //
        switch msg.status {
        case .sending:
            indicatorView.startAnimating()
            statusView.isHidden = true
        case .failed:
            indicatorView.stopAnimating()
            statusView.setImage(R.image.dmSendFailed(), for: .normal)
            statusView.isHidden = false
        default:
            statusView.isHidden = true
            indicatorView.stopAnimating()
        }
        unreadView.isHidden = !(msg.unread == true)
        
        if viewModel.showTime {
            container.top = 33
        } else {
            container.top = 6
        }
        timeLabel.isHidden = !viewModel.showTime
    }
    
    @objc private func statusViewAction() {
        guard let viewModel = viewModel else {
            return
        }
        actionHandler?(.resend(viewModel.message))
    }
    
    private func setUpLayout() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubviews(views: container, timeLabel)
        container.addSubviews(views: avatarImageView, textContainer, statusView, indicatorView)
        
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

}
