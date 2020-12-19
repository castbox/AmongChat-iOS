//
//  AmongChat.Room.MessageCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/4.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension AmongChat.Room {

//    class MessageCell: UITableViewCell {
//
//        private lazy var avatarIV: UIImageView = {
//            let iv = UIImageView()
//            iv.layer.cornerRadius = 12.5
//            iv.layer.masksToBounds = true
//            iv.layer.borderWidth = 0.5
//            iv.layer.borderColor = UIColor.white.alpha(0.8).cgColor
//            return iv
//        }()
//
//        private var avatarDisposable: Disposable?
//
//        private lazy var nameLabel: UILabel = {
//            let lb = UILabel()
//            lb.font = R.font.nunitoRegular(size: 11)
//            lb.textColor = UIColor.white.alpha(0.5)
//            return lb
//        }()
//
//        private lazy var messageView: UIView = {
//            let v = UIView()
//            v.backgroundColor = UIColor.white.alpha(0.2)
//            v.layer.cornerRadius = 5
//            v.addSubview(messageLabel)
//            messageLabel.snp.makeConstraints { (maker) in
//                maker.edges.equalToSuperview().inset(12)
//            }
//            return v
//        }()
//
//        private lazy var messageLabel: UILabel = {
//            let lb = UILabel()
//            lb.font = R.font.nunitoRegular(size: 11)
//            lb.textColor = .white
//            lb.numberOfLines = 0
//            lb.lineBreakMode = .byWordWrapping
//            return lb
//        }()
//
//        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//            super.init(style: style, reuseIdentifier: reuseIdentifier)
//            setupLayout()
//        }
//
//        required init?(coder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//
//        override func layoutSubviews() {
//            super.layoutSubviews()
//        }
//
//        private func setupLayout() {
//            selectionStyle = .none
//            backgroundColor = .clear
//            contentView.backgroundColor = .clear
//
//            contentView.addSubviews(views: avatarIV, nameLabel, messageView)
//
//            avatarIV.snp.makeConstraints { (maker) in
//                maker.size.equalTo(CGSize(width: 25, height: 25))
//                maker.left.equalToSuperview().inset(12)
//                maker.top.equalToSuperview().inset(7)
//            }
//
//            nameLabel.snp.makeConstraints { (maker) in
//                maker.top.equalToSuperview().inset(10)
//                maker.left.equalTo(avatarIV.snp.right).offset(8)
//                maker.right.greaterThanOrEqualToSuperview().inset(30)
//            }
//
//            messageView.snp.makeConstraints { (maker) in
//                maker.top.equalTo(nameLabel.snp.bottom).offset(9)
//                maker.left.equalTo(avatarIV.snp.right).offset(8)
//                maker.right.lessThanOrEqualToSuperview().offset(-30)
//                maker.bottom.equalToSuperview()
//            }
//
//        }
//
//    }

    class MessageTextCell: UITableViewCell {

        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
//            lb.font = R.font.nunitoRegular(size: 11)
//            lb.textColor = UIColor.white.alpha(0.5)
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            return lb
        }()

//        private lazy var messageLabel: UILabel = {
//            let lb = UILabel()
//            lb.font = R.font.nunitoRegular(size: 11)
//            lb.textColor = .white
//            lb.numberOfLines = 0
//            lb.lineBreakMode = .byWordWrapping
//            return lb
//        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
        }

        private func setupLayout() {
            selectionStyle = .none
            backgroundColor = .clear
            contentView.backgroundColor = .clear

            contentView.addSubviews(views: nameLabel)

//            avatarIV.snp.makeConstraints { (maker) in
//                maker.size.equalTo(CGSize(width: 25, height: 25))
//                maker.left.equalToSuperview().inset(12)
//                maker.top.equalToSuperview().inset(7)
//            }

            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(4)
                maker.left.equalTo(20)
                maker.right.lessThanOrEqualTo(-20)
                maker.bottom.equalToSuperview().offset(-4)
            }

//            messageLabel.snp.makeConstraints { (maker) in
//                maker.top.equalTo(nameLabel.snp.bottom).offset(9)
//                maker.left.equalTo(nameLabel.snp.right).offset(8)
//                maker.right.lessThanOrEqualToSuperview().offset(-30)
//                maker.bottom.equalToSuperview()
//            }

        }

    }

}

//extension AmongChat.Room.MessageCell {
//
//    func configCell(with viewModel: AmongChat.Room.MessageViewModel) {
//
//        avatarIV.image = nil
//        let userViewModel = viewModel.user
//        let channelUser = userViewModel.channelUser
//
//        avatarDisposable?.dispose()
//        avatarDisposable = userViewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
//            guard let `self` = self else { return }
//
//            if let _ = image {
//                self.avatarIV.backgroundColor = .clear
//            } else {
//                self.avatarIV.backgroundColor = channelUser.iconColor.color()
//            }
//            self.avatarIV.image = image
//        })
//
//        nameLabel.text = userViewModel.name
//
//        messageLabel.text = viewModel.text
//    }
//
//}

extension AmongChat.Room.MessageTextCell {
    
    func configCell(with message: ChatRoomMessage) {
//        let userViewModel = viewModel.user
//        let channelUser = userViewModel.channelUser
        var user: Entity.RoomUser?
        var text: String = ""
        if let textMessage = message as? ChatRoom.TextMessage {
//            user = textMessage.user
//            text = textMessage.text
            
            let pargraph = NSMutableParagraphStyle()
            pargraph.lineBreakMode = .byTruncatingTail
            pargraph.lineHeightMultiple = 0
            
            let nameAttr: [NSAttributedString.Key: Any] = [
                .foregroundColor: "ABABAB".color(),
                .font: R.font.nunitoExtraBold(size: 12) ?? Font.caption1.value,
                .paragraphStyle: pargraph
    //            .kern: 0.5
            ]
            
            let contentAttr: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: R.font.nunitoSemiBold(size: 12) ?? Font.caption1.value,
                .paragraphStyle: pargraph
    //            .kern: 0.5
            ]
            
            let mutableNormalString = NSMutableAttributedString()
            mutableNormalString.append(NSAttributedString(string: "#\(textMessage.user.seatNo) \(textMessage.user.name)", attributes: nameAttr))
            mutableNormalString.append(NSAttributedString(string: " \(textMessage.content)", attributes: contentAttr))
            nameLabel.attributedText = mutableNormalString
        } else if let systemMessage = message as? ChatRoom.SystemMessage {
            let pargraph = NSMutableParagraphStyle()
            pargraph.lineBreakMode = .byTruncatingTail
            pargraph.lineHeightMultiple = 0
            
            let nameAttr: [NSAttributedString.Key: Any] = [
                .foregroundColor: systemMessage.textColor?.color() ?? "FB5858".color(),
                .font: R.font.nunitoExtraBold(size: 12) ?? Font.caption1.value,
                .paragraphStyle: pargraph
            ]
            
            let mutableNormalString = NSMutableAttributedString()
            mutableNormalString.append(NSAttributedString(string: "\(systemMessage.content)", attributes: nameAttr))
//            mutableNormalString.append(NSAttributedString(string: " \(textMessage.text)", attributes: contentAttr))
            nameLabel.attributedText = mutableNormalString

        }
//        messageLabel.text = viewModel.text
    }
    
}
