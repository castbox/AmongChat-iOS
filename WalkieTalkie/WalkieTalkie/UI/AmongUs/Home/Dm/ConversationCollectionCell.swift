//
//  ConversationCollectionCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NVActivityIndicatorView
import AVFoundation
import Kingfisher

private let avatarLeftEdge: CGFloat = 20
private let contentLeftEdge: CGFloat = 60

class ConversationCollectionCell: UICollectionViewCell {
    
    enum Action {
        case resend(Entity.DMMessage)
        case user(Int64)
        case clickVoiceMessage(Entity.DMMessage)
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
        i.isUserInteractionEnabled = true
        i.rx.tapGesture()
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self, let uid = self.viewModel?.message.fromUser.uid else { return }
                self.actionHandler?(.user(uid))
            })
            .disposed(by: bag)
        return i
    }()
    
    private lazy var textContainer: UIButton = {
        let i = UIButton(frame: CGRect(x: 60, y: 0, width: Frame.Screen.width - 60 * 2, height: 109))
        i.clipsToBounds = true
        i.contentMode = .scaleAspectFill
        i.backgroundColor = "#222222".color()
        i.addTarget(self, action: #selector(clickContentViewAction), for: .primaryActionTriggered)
        
        i.addSubviews(views: messageTextLabel, voiceDurationLabel, voicePlayIndiator, voiceTagView)
        i.roundCorners(topLeft: 2, topRight: 20, bottomLeft: 20, bottomRight: 20)
        
        messageTextLabel.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(12)
        }
        
        voiceDurationLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(12)
            maker.centerY.equalToSuperview()
        }
        
        voicePlayIndiator.snp.makeConstraints { maker in
            maker.right.equalTo(-12)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CGSize(width: 24, height: 30))
        }
        voiceTagView.snp.makeConstraints { maker in
            maker.center.equalTo(voicePlayIndiator)
        }
        return i
    }()
    
    private lazy var messageTextLabel: UILabel = {
        let l = UILabel()
        l.font = R.font.nunitoBold(size: 16)
        l.textColor = UIColor(hex6: 0xFFFFFF)
        l.numberOfLines = 0
        //        l.lineBreakMode = .byWordWrapping
        return l
    }()
    
    private lazy var voiceDurationLabel: UILabel = {
        let l = UILabel()
        l.font = R.font.nunitoBold(size: 16)
        l.textColor = UIColor(hex6: 0xFFFFFF)
        l.numberOfLines = 1
        l.isHidden = true
        //        l.lineBreakMode = .byWordWrapping
        return l
    }()
    
    private lazy var gifImageView: AnimatedImageView = {
        let v = AnimatedImageView()
        v.contentMode = .scaleAspectFit
        v.isHidden = true
        v.isUserInteractionEnabled = false
//        v.backgroundColor = "222222".color()
        return v
    }()
    
    private lazy var voicePlayIndiator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 30), type: .lineScale, color: .white, padding: 0)
    
    private lazy var voiceTagView: UIImageView = {
        let v = UIImageView(image: R.image.iconDmVoiceTag())
        v.contentMode = .scaleAspectFit
        v.isHidden = true
//        v.backgroundColor = "222222".color()
        return v
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
    
    private let bag = DisposeBag()
    
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
        timeLabel.text = viewModel.dateString
        
        switch msg.body.msgType {
        case .text:
            messageTextLabel.text = msg.body.text
            textContainer.size = CGSize(width: viewModel.contentSize.width + 12 * 2, height: viewModel.contentSize.height + 12 * 2)
            messageTextLabel.size = viewModel.contentSize
            container.height = textContainer.size.height
            if viewModel.sendFromMe {
                //avatar
                messageTextLabel.textColor = "#FFF000".color()
                avatarImageView.right = Frame.Screen.width - avatarLeftEdge
                textContainer.right = Frame.Screen.width - contentLeftEdge
                textContainer.roundCorners(topLeft: 20, topRight: 2, bottomLeft: 20, bottomRight: 20)
                statusView.right = textContainer.left - 8
            } else {
                messageTextLabel.textColor = .white
                avatarImageView.left = avatarLeftEdge
                textContainer.left = contentLeftEdge
                textContainer.roundCorners(topLeft: 2, topRight: 20, bottomLeft: 20, bottomRight: 20)
                statusView.left = textContainer.right + 8
            }
            statusView.centerY = textContainer.centerY
            indicatorView.center = statusView.center
            //            textContainer.isHidden = false
            messageTextLabel.isHidden = false
            voiceDurationLabel.isHidden = true
            voicePlayIndiator.isHidden = true
            voiceTagView.isHidden = true
            textContainer.isHidden = false
            gifImageView.isHidden = true
        case .gif:
            gifImageView.size = viewModel.contentSize
            container.height = gifImageView.size.height
            if viewModel.sendFromMe {
                avatarImageView.right = Frame.Screen.width - avatarLeftEdge
                gifImageView.right = Frame.Screen.width - contentLeftEdge
                statusView.right = gifImageView.left - 8
                statusView.centerY = gifImageView.centerY
                indicatorView.center = statusView.center
                gifImageView.setImage(with: msg.body.img)
            } else {
                avatarImageView.left = avatarLeftEdge
                gifImageView.left = contentLeftEdge
                statusView.left = gifImageView.right + 8
                statusView.centerY = statusView.centerY
                indicatorView.center = gifImageView.center
                indicatorView.startAnimating()
                gifImageView.setImage(with: msg.body.img, completionHandler: { [weak self] result in
                    self?.indicatorView.stopAnimating()
                })
            }
            voiceDurationLabel.isHidden = false
            voicePlayIndiator.isHidden = true
            voiceTagView.isHidden = true
            messageTextLabel.isHidden = true
            textContainer.isHidden = true
            gifImageView.isHidden = false
        case .voice:
            textContainer.size = viewModel.contentSize
            voiceDurationLabel.text = "\(viewModel.message.body.duration ?? 0)″"
            if viewModel.sendFromMe {
                //avatar
                voiceDurationLabel.textColor = "#FFF000".color()
                avatarImageView.right = Frame.Screen.width - avatarLeftEdge
                textContainer.right = Frame.Screen.width - contentLeftEdge
                textContainer.roundCorners(topLeft: 18, topRight: 2, bottomLeft: 18, bottomRight: 18)
                statusView.right = textContainer.left - 8
                voicePlayIndiator.color = "#FFF000".color()
                unreadView.right = statusView.right
                
            } else {
                voiceDurationLabel.textColor = .white
                voicePlayIndiator.color = .white
                avatarImageView.left = avatarLeftEdge
                textContainer.left = contentLeftEdge
                textContainer.roundCorners(topLeft: 2, topRight: 18, bottomLeft: 18, bottomRight: 18)
                statusView.left = textContainer.right + 8
                unreadView.left = statusView.left
            }
            if let path = msg.body.localAbsolutePath, AudioPlayerManager.default.isPlaying(path) {
                startVoicePlay(animated: true)
            } else {
                startVoicePlay(animated: false)
            }
            voiceTagView.tintColor = voicePlayIndiator.color
            statusView.centerY = textContainer.centerY
            indicatorView.center = statusView.center
            unreadView.isHidden = !(msg.unread ?? false)
            unreadView.centerY = textContainer.centerY
            voiceDurationLabel.isHidden = false
            voicePlayIndiator.isHidden = false
            textContainer.isHidden = false
            messageTextLabel.isHidden = true
            gifImageView.isHidden = true
        case .none:
            ()
        }
        switch msg.status {
        case .sending, .downloading:
            indicatorView.startAnimating()
            statusView.isHidden = true
            unreadView.isHidden = true
        case .failed:
            indicatorView.stopAnimating()
            statusView.setImage(R.image.dmSendFailed(), for: .normal)
            statusView.isHidden = false
            unreadView.isHidden = true
        default:
            statusView.isHidden = true
            indicatorView.stopAnimating()
            unreadView.isHidden = !(msg.unread == true)
        }
        
        if viewModel.showTime {
            container.top = 33
        } else {
            container.top = 6
        }
        timeLabel.isHidden = !viewModel.showTime
    }
    
    @objc func clickContentViewAction() {
        guard let viewModel = viewModel,
              let path = viewModel.message.body.localAbsolutePath,
              !AudioPlayerManager.default.isPlaying(path) else {
            startVoicePlay(animated: false)
            AudioPlayerManager.default.stopPlay()
            return
        }
        startVoicePlay(animated: true)
         AudioPlayerManager.default.play(fileUrl: path) { [weak self] in
            self?.startVoicePlay(animated: false)
        }
        actionHandler?(.clickVoiceMessage(viewModel.message))
    }
    
    func startVoicePlay(animated: Bool) {
        if animated {
            voicePlayIndiator.startAnimating()
            voiceTagView.isHidden = true
        } else {
            voiceTagView.isHidden = false
            voicePlayIndiator.stopAnimating()
        }
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
        container.addSubviews(views: avatarImageView, textContainer, gifImageView, statusView, indicatorView, unreadView)
    }
}
