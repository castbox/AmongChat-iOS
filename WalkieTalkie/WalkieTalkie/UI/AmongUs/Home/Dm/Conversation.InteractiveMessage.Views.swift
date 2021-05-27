//
//  InteractiveOpTypeView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 27/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Conversation {
    class InteractiveNavigationBar: UIView {
        
        static let barHeight: CGFloat = 49
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.textAlignment = .center
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.dmInteractiveAllMessage()
            return lb
        }()
        
        private lazy var imageView = UIImageView(image: R.image.iconDmArrowDown())
        private lazy var titleContainer: UIStackView = {
            imageView.contentMode = .center
            
            let v = UIStackView(arrangedSubviews: [titleLabel, imageView], axis: .horizontal)
            v.spacing = 4
            return v
        }()
        
        private(set) lazy var leftBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setImage(R.image.ac_back(), for: .normal)
            return btn
        }()
        
        private(set) lazy var backgroundView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x121212)
            v.isHidden = true
            return v
        }()
        
        private lazy var opTypeView: InteractiveOpTypeView = {
            let v = InteractiveOpTypeView()
            v.isHidden = true
            return v
        }()
        
        private let bag = DisposeBag()
        
        var type: Entity.DMInteractiveMessage.OpType?
        
        var selectHandler: ((Entity.DMInteractiveMessage.OpType?) -> Void)?
        
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
            bindSubviewEvent()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            addSubviews(views: backgroundView, titleContainer, leftBtn)
            clipsToBounds = false
            
            let layoutGuide = UILayoutGuide()
            addLayoutGuide(layoutGuide)
            layoutGuide.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.height.equalTo(Self.barHeight)
            }
            
            backgroundView.snp.makeConstraints { (maker) in
                maker.leading.bottom.trailing.equalToSuperview()
                maker.top.equalToSuperview().offset(-Frame.Height.safeAeraTopHeight)
            }
            
            leftBtn.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
            }
            
            titleContainer.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.leading.greaterThanOrEqualTo(leftBtn.snp.trailing).offset(20)
                maker.height.equalTo(33)
            }
            
        }
        
        func bindSubviewEvent() {
            titleContainer.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.showOpTypeView()
                })
                .disposed(by: bag)
            
            opTypeView.selectHandler = { [weak self] type in
                self?.type = type
                self?.selectHandler?(type)
            }
        }
    
        func showOpTypeView() {
            if opTypeView.superview == nil {
                self.superview?.addSubview(opTypeView)
                opTypeView.frame = Frame.Screen.bounds
            }
            self.superview?.bringSubviewToFront(opTypeView)
            imageView.transform = imageView.transform.rotated(by: .pi)
            opTypeView.show(with: type) { [weak self] in
                guard let `self` = self else { return }
                self.imageView.transform = self.imageView.transform.rotated(by: .pi)
            }
        }
    }
    
    class InteractiveOpTypeView: UIView {
        
        private lazy var container: UIView = {
           let v = UIView()
            v.backgroundColor = "222222".color()
            v.cornerRadius = 12
            v.clipsToBounds = true
            return v
        }()
        
        private lazy var imageView = UIImageView(image: R.image.iconDmInteractiveSelect())
        
        private(set) lazy var allMessageBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setTitle(R.string.localizable.dmInteractiveAllMessage(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 18)
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            return btn
        }()

        private(set) lazy var commentBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setTitle(R.string.localizable.dmInteractiveComments(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 18)
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            return btn
        }()

        private(set) lazy var emotesBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setTitle(R.string.localizable.dmInteractiveEmotes(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 18)
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            return btn
        }()
        
        private(set) lazy var likeBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setTitle(R.string.localizable.dmInteractiveLikes(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 18)
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            return btn
        }()
        
        private let bag = DisposeBag()
        
        var type: Entity.DMInteractiveMessage.OpType? {
            didSet {
                guard let type = type else {
                    imageView.centerY = allMessageBtn.centerY
                    return
                }
                switch type {
                case .comment:
                    imageView.centerY = commentBtn.centerY
                case .emotes:
                    imageView.centerY = emotesBtn.centerY
                case .like:
                    imageView.centerY = likeBtn.centerY
                }
            }
        }
        
        var selectHandler: ((Entity.DMInteractiveMessage.OpType?) -> Void)?
        private var dismissHandler: CallBack?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            configureSubview()
            bindSubviewEvent()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func show(with type: Entity.DMInteractiveMessage.OpType?, dismissHandler: CallBack?) {
            self.type = type
            self.dismissHandler = dismissHandler
            fadeIn(duration: 0.25)
        }
        
        func dismiss() {
            selectHandler?(type)
            dismissHandler?()
            fadeOut(duration: 0.25)
        }
        
        private func bindSubviewEvent() {
            allMessageBtn.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.type = nil
                    self?.dismiss()
                })
                .disposed(by: bag)
            
            commentBtn.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.type = .comment
                    self?.dismiss()
                })
                .disposed(by: bag)
            
            emotesBtn.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.type = .emotes
                    self?.dismiss()
                })
                .disposed(by: bag)
            
            likeBtn.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.type = .like
                    self?.dismiss()
                })
                .disposed(by: bag)
            
            rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.dismiss()
                })
                .disposed(by: bag)
        }
        
        private func configureSubview() {
            backgroundColor = UIColor.black.alpha(0.7)
            addSubviews(views: container)
            container.addSubviews(views: allMessageBtn, commentBtn, emotesBtn, likeBtn, imageView)
            
            let itemWidth: CGFloat = 202
            container.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(Frame.Height.navigation)
                maker.width.greaterThanOrEqualTo(itemWidth)
                maker.height.equalTo(276)
            }

            allMessageBtn.frame = CGRect(x: 0, y: 28, width: itemWidth, height: 40)
            commentBtn.frame = CGRect(x: 0, y: allMessageBtn.bottom + 20, width: itemWidth, height: 40)
            emotesBtn.frame = CGRect(x: 0, y: commentBtn.bottom + 20, width: itemWidth, height: 40)
            likeBtn.frame = CGRect(x: 0, y: emotesBtn.bottom + 20, width: itemWidth, height: 40)
            imageView.frame = CGRect(x: itemWidth - 44, y: 0, width: 24, height: 24)
            imageView.centerY = allMessageBtn.centerY
        }

    }
}
