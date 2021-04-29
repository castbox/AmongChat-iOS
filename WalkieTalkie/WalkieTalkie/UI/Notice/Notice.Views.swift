//
//  Notice+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Notice {
    struct Views {
        
    }
}

protocol NoticeCellGeometory {
        
    static func cellSize(for notice: Entity.Notice) -> CGSize
}

extension NoticeCellGeometory {
    
    static var cellWidth: CGFloat {
        var hInset: CGFloat = 20
        var columns: Int = 1
        let interitemSpacing: CGFloat = 20
        let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
        return cellWidth
    }
    
}

extension Notice.Views {
    
    class SocialMessageCell: UICollectionViewCell, NoticeCellGeometory {
        
        private static let titleHeight:CGFloat = 27
        private static let textLeading: CGFloat = 12
        private static let messageTopPadding: CGFloat = 1
        private static let textFont = R.font.nunitoBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold)
        private static let imageViewSize = CGSize(width: 48, height: 48)
        private static let timeLableTopPadding: CGFloat = 4
        private static let timeLableHeight: CGFloat = 19
        
        static func cellSize(for notice: Entity.Notice) -> CGSize {
                        
            let txtHeight = notice.message.text.height(forConstrainedWidth: cellWidth - imageViewSize.width - textLeading, font: Self.textFont)
            
            let height = ceil(titleHeight + messageTopPadding + txtHeight + timeLableTopPadding + timeLableHeight)
            return CGSize(width: cellWidth, height: height)
        }
        
        private lazy var timeLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0x595959)
            return l
        }()
        
        private lazy var messageImageView: UIImageView = {
            let i = UIImageView()
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var messageTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 20)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            return l
        }()
        
        private lazy var messageTextLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            l.numberOfLines = 0
            l.lineBreakMode = .byWordWrapping
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
            
            contentView.addSubviews(views: messageImageView, messageTitleLabel, messageTextLabel, timeLabel)
            
            messageImageView.snp.makeConstraints { (maker) in
                maker.top.leading.equalToSuperview()
                maker.size.equalTo(Self.imageViewSize)
            }
            
            messageTitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(messageImageView)
                maker.leading.equalTo(messageImageView.snp.trailing).offset(Self.textLeading)
                maker.trailing.equalToSuperview()
                maker.height.equalTo(Self.titleHeight)
            }
            
            messageTextLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(messageTitleLabel)
                maker.top.equalTo(messageTitleLabel.snp.bottom).offset(Self.messageTopPadding)
            }
            
            timeLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(messageTitleLabel)
                maker.height.equalTo(Self.timeLableHeight)
                maker.top.equalTo(messageTextLabel.snp.bottom).offset(Self.timeLableTopPadding)
                maker.bottom.equalToSuperview()
            }
            
        }
        
        func bindNoticeData(_ noticeVM: Notice.NoticeViewModel) {
            let notice = noticeVM.notice

            messageImageView.setImage(with: notice.message.img)
            messageTitleLabel.text = notice.message.title
            messageTextLabel.text = notice.message.text
            timeLabel.text = noticeVM.timeString
            
            switch notice.message.messageObjType {
            case .group, .room, .unknown:
                messageImageView.layer.cornerRadius = 12
            case .user:
                messageImageView.layer.cornerRadius = Self.imageViewSize.height / 2
            }
            
        }

    }
    
}

extension Notice.Views {
    
    class SystemMessageCell: UICollectionViewCell, NoticeCellGeometory {
        
        private static let timeLableHeight: CGFloat = 19
        private static let aboveTextImageHeight: CGFloat = 170
        private static let textHPadding: CGFloat = 16
        private static let titleTopPadding: CGFloat = 16
        private static let titleFont = R.font.nunitoExtraBold(size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .heavy)
        private static let messageTopPadding: CGFloat = 8
        private static let textFont = R.font.nunitoBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold)
        private static let belowTextImageSize = CGSize(width: 80, height: 80)
        private static let belowTextImageTopPadding: CGFloat = 12
        private static let messageBodyBottomPadding: CGFloat = 24
        private static let containerTopPadding: CGFloat = 8
        private static let actionViewHeight: CGFloat = 52

        static func cellSize(for notice: Entity.Notice) -> CGSize {
            
            var containerHeight: CGFloat = 0
            
            let titleHeight = notice.message.title.height(forConstrainedWidth: cellWidth - textHPadding * 2, font: Self.titleFont)
            let txtHeight = notice.message.text.height(forConstrainedWidth: cellWidth - textHPadding * 2, font: Self.textFont)
            containerHeight = titleTopPadding + titleHeight + messageTopPadding + txtHeight + messageBodyBottomPadding
            
            switch notice.message.messageType {
            
            case .TxtMsg:
                ()
                
            case .ImgTxtMsg:
                
                containerHeight = containerHeight + aboveTextImageHeight

            case .ImgMsg:
                ()
                
            case .TxtImgMsg:
                
                containerHeight = containerHeight + belowTextImageTopPadding + belowTextImageSize.height
                
            default:
                ()
            }
            
            if let _ = notice.message.link {
                
                containerHeight = containerHeight + actionViewHeight
                
            }
            
            let height = ceil(containerHeight + containerTopPadding + timeLableHeight)
            
            return CGSize(width: cellWidth, height: height)
        }
        
        private lazy var timeLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textAlignment = .center
            l.textColor = UIColor(hex6: 0x595959)
            return l
        }()
        
        private lazy var container: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x202020)
            v.layer.cornerRadius = 12
            v.clipsToBounds = true
            return v
        }()
        
        private lazy var aboveTextImageView: UIImageView = {
            let i = UIImageView()
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var belowTextImageView: UIImageView = {
            let i = UIImageView()
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFit
            return i
        }()
        
        private lazy var messageTitleLabel: UILabel = {
            let l = UILabel()
            l.font = Self.titleFont
            l.textColor = UIColor(hex6: 0xFFFFFF)
            l.numberOfLines = 0
            l.lineBreakMode = .byWordWrapping
            return l
        }()
        
        private lazy var messageTextLabel: UILabel = {
            let l = UILabel()
            l.font = Self.textFont
            l.textColor = UIColor(hex6: 0x898989)
            l.numberOfLines = 0
            l.lineBreakMode = .byWordWrapping
            return l
        }()
        
        private lazy var actionView: UIView = {
            
            let v = UIView()
            
            let line: UIView = {
                let v = UIView()
                v.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.06)
                return v
            }()
            
            let titleLabel: UILabel = {
                let l = UILabel()
                l.font = R.font.nunitoExtraBold(size: 16)
                l.textColor = UIColor(hex6: 0x898989)
                l.text = R.string.localizable.amongChatNoticeClickToGo()
                return l
            }()
            
            let icon = UIImageView(image: R.image.ac_notice_next())
            
            v.addSubviews(views: line, titleLabel, icon)
            
            line.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(1)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(16)
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(icon.snp.leading).offset(-8)
                maker.height.equalTo(22)
            }
            
            icon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(titleLabel.snp.trailing).offset(8)
                maker.trailing.lessThanOrEqualTo(-16)
            }
            return v
        }()
        
        var actionHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = .clear
            
            container.addSubviews(views: aboveTextImageView, messageTitleLabel, messageTextLabel, belowTextImageView, actionView)
            
            aboveTextImageView.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(Self.aboveTextImageHeight)
            }
            
            messageTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Self.textHPadding)
                maker.top.equalTo(aboveTextImageView.snp.bottom).offset(Self.titleTopPadding)
            }
            
            messageTextLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(messageTitleLabel)
                maker.top.equalTo(messageTitleLabel.snp.bottom).offset(Self.messageTopPadding)
            }
            
            belowTextImageView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(messageTitleLabel)
                maker.top.equalTo(messageTextLabel.snp.bottom).offset(Self.belowTextImageTopPadding)
                maker.size.equalTo(Self.belowTextImageSize)
            }
            
            actionView.snp.makeConstraints { (maker) in
                maker.leading.bottom.trailing.equalToSuperview()
                maker.height.equalTo(Self.actionViewHeight)
            }
            
            contentView.addSubviews(views: timeLabel, container)
            
            timeLabel.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(Self.timeLableHeight)
            }

            container.snp.makeConstraints { (maker) in
                maker.top.equalTo(timeLabel.snp.bottom).offset(Self.containerTopPadding)
                maker.leading.trailing.bottom.equalToSuperview()
            }
            
        }
        
        func bindNoticeData(_ noticeVM: Notice.NoticeViewModel) {
            let notice = noticeVM.notice
            
            messageTitleLabel.text = notice.message.title
            messageTextLabel.text = notice.message.text
            timeLabel.text = noticeVM.timeString
            
            switch notice.message.messageType {
            case .TxtMsg:
                aboveTextImageView.image = nil
                aboveTextImageView.isHidden = true
                belowTextImageView.image = nil
                belowTextImageView.isHidden = true
                aboveTextImageView.snp.remakeConstraints { (maker) in
                    maker.leading.top.trailing.equalToSuperview()
                    maker.height.equalTo(0)
                }
                
            case .ImgTxtMsg:
                aboveTextImageView.setImage(with: notice.message.img)
                aboveTextImageView.isHidden = false
                belowTextImageView.image = nil
                belowTextImageView.isHidden = true
                aboveTextImageView.snp.remakeConstraints { (maker) in
                    maker.leading.top.trailing.equalToSuperview()
                    maker.height.equalTo(Self.aboveTextImageHeight)
                }

            case .ImgMsg, .TxtImgMsg:
                aboveTextImageView.image = nil
                aboveTextImageView.isHidden = true
                belowTextImageView.setImage(with: notice.message.img)
                belowTextImageView.isHidden = false

            default:
                aboveTextImageView.image = nil
                aboveTextImageView.isHidden = true
                belowTextImageView.image = nil
                belowTextImageView.isHidden = true
                
            }
            
            actionView.isHidden = notice.message.link?.isEmpty ?? true
            
        }
        
    }
    
    
}
