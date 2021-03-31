//
//  FansGroup.Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/29.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension FansGroup {
    struct Views {}
}

extension FansGroup.Views {
    
    class NavigationBar: UIView {
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.textAlignment = .center
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private(set) lazy var leftBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            return btn
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            addSubviews(views: titleLabel, leftBtn)
            
            leftBtn.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.centerY.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.leading.equalToSuperview().inset(64)
            }
            
        }
        
    }
    
}

extension FansGroup.Views {
    
    class LeftEclipseView: UIView {
        
        var gap: CGFloat = 2 {
            didSet {
                setNeedsDisplay()
            }
        }
        
        var fillColor: UIColor = UIColor(hex6: 0xFFFFFF, alpha: 0.12) {
            didSet {
                setNeedsDisplay()
            }
        }
        
        init() {
            super.init(frame: .zero)
            backgroundColor = .clear
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            setNeedsDisplay()
        }
        
        override func draw(_ rect: CGRect) {
            
            let smallR = rect.height / 2
            let bigR = smallR + gap
            
            let arcCenter = CGPoint(x: smallR, y: smallR)
            
            let theta = asin(smallR / bigR)
            
            let path = UIBezierPath(arcCenter: arcCenter, radius: bigR, startAngle: -(theta), endAngle: theta, clockwise: true)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.close()
            fillColor.set()
            path.fill()
        }
        
    }
    
    class GroupTopicView: UIView {
        
        private(set) lazy var cover: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            i.clipsToBounds = true
            return i
        }()
        
        private(set) lazy var nameLabel: UILabel = {
            let l = UILabel()
            l.font = Self.nameFont
            l.textColor = UIColor.white
            return l
        }()
        
        private lazy var bg: LeftEclipseView = {
            let v = LeftEclipseView()
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            cover.layer.cornerRadius = cover.bounds.height / 2
        }
        
        private func setUpLayout() {
            addSubviews(views: bg, cover, nameLabel)
            
            bg.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            cover.snp.makeConstraints { (maker) in
                maker.left.top.bottom.equalToSuperview()
                maker.width.equalTo(cover.snp.height)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(cover.snp.right).offset(Self.nameInset.left)
                maker.right.equalToSuperview().inset(Self.nameInset.right)
                maker.top.bottom.equalToSuperview()
            }
        }
        
        private static let nameFont = R.font.nunitoExtraBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .heavy)
        
        private static let nameInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 12)
        
        class func viewSize(for topicName: String, coverSize: CGSize) -> CGSize {
            let width = topicName.width(withConstrainedHeight: coverSize.height, font: nameFont) + coverSize.width + nameInset.left + nameInset.right
            return CGSize(width: width, height: coverSize.height)
        }
        
    }
    
}

extension FansGroup.Views {
    class GroupTopicCell: UICollectionViewCell {
        
        private lazy var topicView: GroupTopicView = {
            let t = GroupTopicView()
            return t
        }()
        
        override var isSelected: Bool {
            didSet {
                if isSelected {
                    contentView.layer.borderWidth = 2
                    contentView.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
                } else {
                    contentView.layer.borderWidth = 0
                    contentView.layer.borderColor = nil
                }
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layoutIfNeeded()
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.layer.cornerRadius = 16
            contentView.clipsToBounds = true
            
            contentView.addSubviews(views: topicView)
            topicView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
        func bindViewModel(_ viewModel: FansGroup.TopicViewModel) {
            topicView.cover.setImage(with: viewModel.coverUrl?.url)
            topicView.nameLabel.text = viewModel.name
        }
        
    }
}

extension FansGroup.Views {
    
    class GroupNameView: UIView, UITextFieldDelegate {
        
        private let maxInputLength = Int(30)
        
        private(set) lazy var inputField: UITextField = {
            let f = UITextField()
            f.backgroundColor = .clear
            f.borderStyle = .none
            f.keyboardAppearance = .dark
            f.returnKeyType = .done
            f.attributedPlaceholder = NSAttributedString(string: R.string.localizable.amongChatGroupNamePlaceholder(),
                                                         attributes: [
                                                            NSAttributedString.Key.foregroundColor : UIColor(hex6: 0x363636)
                                                         ])
            f.textColor = .white
            f.delegate = self
            f.font = R.font.nunitoExtraBold(size: 18)
            return f
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = UIColor(hex6: 0x1A1A1A)
            layer.cornerRadius = 12
            layer.masksToBounds = true
            
            addSubviews(views: inputField)
            
            inputField.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            }
        }
        
        // MARK: - UITextField Delegate
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let textFieldText = textField.text,
                  let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
            }
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + string.count
            return count <= maxInputLength
        }
        
    }
    
}

extension FansGroup.Views {
    
    class GroupDescriptionView: UIView, UITextViewDelegate {
        
        private let bag = DisposeBag()
        
        private let maxInputLength = Int(280)
        private let textViewMinHeight = CGFloat(74)
        
        private(set) lazy var inputTextView: UITextView = {
            let f = UITextView()
            f.backgroundColor = .clear
            f.keyboardAppearance = .dark
            f.returnKeyType = .done
            f.textContainerInset = .zero
            f.textContainer.lineFragmentPadding = 0
            f.delegate = self
            f.font = R.font.nunitoExtraBold(size: 18)
            f.textColor = .white
            f.rx.text
                .subscribe(onNext: { [weak self] (text) in
                    
                    guard let `self` = self else { return }
                    
                    self.countLabel.text = "\(text?.count ?? 0)/\(self.maxInputLength)"
                    
                    self.placeholderLabel.isHidden = (text != nil) && text!.count > 0
                    
                })
                .disposed(by: bag)
            f.showsVerticalScrollIndicator = false
            f.showsHorizontalScrollIndicator = false
            return f
        }()
        
        private lazy var placeholderLabel: UILabel = {
            let l = UILabel()
            l.numberOfLines = 0
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0x363636)
            l.text = R.string.localizable.amongChatGroupDescriptionPlaceholder()
            return l
        }()
        
        private lazy var countLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0x464646)
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
            
            backgroundColor = UIColor(hex6: 0x1A1A1A)
            layer.cornerRadius = 12
            layer.masksToBounds = true
            
            addSubviews(views: inputTextView, placeholderLabel, countLabel)
            
            inputTextView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 39, right: 16))
                maker.height.equalTo(textViewMinHeight)
            }
            
            placeholderLabel.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalTo(inputTextView)
                maker.bottom.lessThanOrEqualTo(inputTextView)
            }
            
            countLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(16)
                maker.height.equalTo(19)
                maker.top.equalTo(inputTextView.snp.bottom).offset(8)
            }
        }
        
        // MARK: - UITextView Delegate
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let textFieldText = textView.text,
                  let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
            }
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + text.count
            return count <= maxInputLength
        }
    }
    
}

extension FansGroup.Views {
    
    class GroupBigCoverView: UIView {
        
        private(set) lazy var coverIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            return iv
        }()
        
        private lazy var blurView: UIVisualEffectView = {
            let b = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            return b
        }()
        
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            addCorner(with: 24, corners: [.bottomLeft, .bottomRight])
        }
        
        private func setUpLayout() {
            
            clipsToBounds = true
            
            addSubviews(views: coverIV, blurView)
            
            coverIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            blurView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
    }
    
}

extension FansGroup.Views {
    
    class GroupAddCoverView: UIView {
        
        private let bag = DisposeBag()
        
        private(set) lazy var coverIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.rx.observe(UIImage.self, "image")
                .subscribe(onNext: { [weak self] (image) in
                    
                    guard let `self` = self,
                          self.editable else { return }
                    
                    self.addIcon.isHidden = (image != nil)
                    self.changeIcon.isHidden = (image != nil)
                    
                })
                .disposed(by: bag)
            return iv
        }()
        
        private(set) lazy var addIcon: UIImageView = {
            let iv = UIImageView(image: R.image.ac_group_cover_add())
            return iv
        }()
        
        private(set) lazy var changeIcon: UIImageView = {
            let iv = UIImageView(image: R.image.ac_group_cover_edit())
            return iv
        }()
        
        private lazy var tapGR: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event.subscribe(onNext: { [weak self] (_) in
                self?.tapHandler?()
            })
            .disposed(by: bag)
            return g
        }()
        
        var editable: Bool = true {
            didSet {
                changeIcon.isHidden = !editable
                addIcon.isHidden = !editable
            }
        }
        
        var tapHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = UIColor(hex6: 0x303030)
            layer.cornerRadius = 12
            layer.masksToBounds = true
            
            addGestureRecognizer(tapGR)
            
            addSubviews(views: coverIV, addIcon, changeIcon)
            
            coverIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            addIcon.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
            }
            
            changeIcon.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(4)
                maker.bottom.equalToSuperview().inset(2)
            }
            
        }
        
    }
    
}

extension FansGroup.Views {
    
    class GroupTopicSetView: UIView {
        
        private let bag = DisposeBag()
        
        private(set) lazy var placeholderLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0x363636)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.amongChatAddATopic()
            return l
        }()
        
        private(set) lazy var topicView: GroupTopicView = {
            let t = GroupTopicView()
            t.isHidden = true
            return t
        }()
        
        private lazy var addButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.tapHandler?()
                })
                .disposed(by: bag)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor.white.alpha(0.2)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 19, bottom: 0, right: 19)
            btn.setTitle(R.string.localizable.amongChatAdd(), for: .normal)
            return btn
        }()
        
        private lazy var accessoryIV: UIImageView = {
            let i = UIImageView()
            i.isHidden = true
            return i
        }()
        
        private lazy var tapGR: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event.subscribe(onNext: { [weak self] (_) in
                self?.tapHandler?()
            })
            .disposed(by: bag)
            return g
        }()
        
        var tapHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            
            addGestureRecognizer(tapGR)
            
            addSubviews(views: placeholderLabel, topicView, addButton, accessoryIV)
            
            placeholderLabel.snp.makeConstraints { (maker) in
                maker.leading.centerY.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(addButton.snp.leading).offset(-20)
            }
            
            addButton.snp.makeConstraints { (maker) in
                maker.top.bottom.trailing.equalToSuperview()
                maker.height.equalTo(32)
            }
            
            topicView.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
            }
            
            accessoryIV.snp.makeConstraints { (maker) in
                maker.centerY.trailing.equalToSuperview()
            }
        }
        
        func bindViewModel(_ viewModel: FansGroup.TopicViewModel) {
            
            placeholderLabel.isHidden = true
            addButton.isHidden = true
            
            topicView.isHidden = false
            accessoryIV.isHidden = false
            
            topicView.cover.setImage(with: viewModel.coverUrl?.url)
            topicView.nameLabel.text = viewModel.name
        }
        
    }
}

extension FansGroup.Views {
    
    class GroupInfoSetUpView: UIView {
        
        private(set) lazy var topBg: GroupBigCoverView = {
            let b = GroupBigCoverView()
            return b
        }()
        
        private(set) lazy var addCoverBtn: GroupAddCoverView = {
            let a = GroupAddCoverView()
            return a
        }()
        
        private lazy var nameTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.amongChatGroupName()
            return l
        }()
        
        private(set) lazy var nameView: GroupNameView = {
            let n = GroupNameView()
            return n
        }()
        
        private lazy var descriptionTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.amongChatGroupDescription()
            return l
        }()
        
        private(set) lazy var descriptionView: GroupDescriptionView = {
            let d = GroupDescriptionView()
            return d
        }()
        
        private lazy var topicTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.amongChatGroupTopic()
            return l
        }()
        
        private(set) lazy var topicSetView: GroupTopicSetView = {
            let t = GroupTopicSetView()
            return t
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
            
            addSubviews(views: topBg, addCoverBtn, nameTitleLabel, nameView, descriptionTitleLabel, descriptionView, topicTitleLabel, topicSetView)
            
            topBg.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(254.0)
            }
            
            addCoverBtn.snp.makeConstraints { (maker) in
                maker.leading.equalTo(20)
                maker.top.equalTo(117)
                maker.width.height.equalTo(97)
            }
            
            nameTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(22)
                maker.top.equalTo(topBg.snp.bottom).offset(24)
            }
            
            nameView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(56)
                maker.top.equalTo(nameTitleLabel.snp.bottom).offset(12)
            }
            
            descriptionTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(22)
                maker.top.equalTo(nameView.snp.bottom).offset(36)
            }
            
            descriptionView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(descriptionTitleLabel.snp.bottom).offset(12)
            }
            
            topicTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(22)
                maker.top.equalTo(descriptionView.snp.bottom).offset(36)
            }
            
            topicSetView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
                maker.top.equalTo(topicTitleLabel.snp.bottom).offset(12)
                maker.bottom.equalToSuperview()
            }
            
        }
        
    }
    
}
