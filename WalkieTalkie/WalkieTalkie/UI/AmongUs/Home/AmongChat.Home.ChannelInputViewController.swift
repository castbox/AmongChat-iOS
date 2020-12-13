//
//  AmongChat.Home.ChannelInputViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/13.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class ChannelInputViewController: WalkieTalkie.ViewController {
        // MARK: -
        
        private lazy var bgTapGr: UITapGestureRecognizer = {
            let gr = UITapGestureRecognizer(target: self, action: #selector(onBgTapped))
            return gr
        }()
        
        private lazy var hashTagBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.blackOpsOneRegular(size: 30)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle("#", for: .normal)
            btn.layer.cornerRadius = 10
            btn.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)
            return btn
        }()
        
        private lazy var codeField: ChannelNameField = {
            let f = ChannelNameField()
            f.clearButtonMode = .never
            f.placeholder = "PASSCODE"
            f.font = R.font.nunitoBold(size: 17)
            f.keyboardType = .asciiCapable
            
            let lb = UILabel()
            lb.font = R.font.blackOpsOneRegular(size: 30)
            lb.textColor = .black
            lb.text = "#"
            
            f.leftView = lb
            f.leftViewMode = .always
            
            return f
        }()
        
        private lazy var confirmButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 10
            btn.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)
            btn.setImage(R.image.backNor()?.rotated(by: .pi)?.withRenderingMode(.alwaysTemplate), for: .normal)
            btn.tintColor = .white
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var channelFieldContainer: UIView = {
            let v = UIView()
            v.layer.cornerRadius = 10
            v.backgroundColor = UIColor.white.alpha(0.8)
            
            v.addSubviews(views: codeField, confirmButton)
            
            codeField.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().inset(10)
                maker.top.bottom.equalToSuperview()
            }
            
            confirmButton.snp.makeConstraints { (maker) in
                maker.left.equalTo(codeField.snp.right).offset(10)
                maker.right.equalToSuperview().inset(10)
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
            }
            
            return v
        }()
        
        private lazy var navLayoutGuide = UILayoutGuide()
        
        var joinChannel: (String, Bool) -> Void = { _, _ in }
        
        var onDismiss: (() -> Void)? = nil
        
        // MARK: -
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvents()
        }
        
    }
    
}

extension AmongChat.Home.ChannelInputViewController {
    
    @objc
    private func onBgTapped() {
        view.endEditing(true)
        dismiss()
    }
    
    @objc
    private func onConfirmBtn() {
        guard let name = codeField.text,
              !name.isEmpty else {
            return
        }
        
        let joinBlock = { [weak self] in
            guard let `self` = self else { return }
            _ = self.codeField.resignFirstResponder()
            self.joinChannel(name, false)
            self.dismiss()
        }
        
        joinBlock()
    }
}

extension AmongChat.Home.ChannelInputViewController {
    
    private func setupLayout() {
        
        view.backgroundColor = UIColor.black.alpha(0.2)
        
        view.addSubviews(views: channelFieldContainer, hashTagBtn)
        
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(60)
        }
        
        hashTagBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(10)
            maker.width.height.equalTo(40)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        channelFieldContainer.snp.makeConstraints { (maker) in
            maker.edges.equalTo(hashTagBtn)
        }
        channelFieldContainer.alpha = 0
        
        view.addGestureRecognizer(bgTapGr)
    }
    
    private func setupEvents() {
        
        rx.viewDidAppear
            .take(1)
            .subscribe { [weak self] (_) in
                self?.showupAnimation()
            }
            .disposed(by: bag)
    }
    
    private func showupAnimation() {
        
        channelFieldContainer.snp.remakeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(25)
            maker.trailing.equalToSuperview().offset(-25)
            maker.height.equalTo(60)
            maker.top.equalTo(navLayoutGuide.snp.bottom)
        }
        
        hashTagBtn.snp.remakeConstraints { (maker) in
            maker.right.equalTo(channelFieldContainer.snp.right)
            maker.width.height.equalTo(40)
            maker.centerY.equalTo(channelFieldContainer)
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) { [weak self] in
            
            self?.channelFieldContainer.alpha = 1
            self?.hashTagBtn.alpha = 0
            
            self?.view.layoutIfNeeded()
            
        } completion: { [weak self] (_) in
            self?.codeField.becomeFirstResponder()
        }
        
    }
    
    private func dismissAnimation(_ completion: @escaping (() -> Void)) {
        
        channelFieldContainer.snp.remakeConstraints { (maker) in
            maker.edges.equalTo(hashTagBtn)
        }
        
        hashTagBtn.snp.remakeConstraints { (maker) in
            maker.right.equalToSuperview().inset(10)
            maker.width.height.equalTo(40)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) { [weak self] in
            self?.channelFieldContainer.alpha = 0
            self?.hashTagBtn.alpha = 1
            self?.view.layoutIfNeeded()
        } completion: { (_) in
            completion()
        }
        
    }
    
    private func dismiss() {
        dismissAnimation { [weak self] in
            self?.dismiss(animated: false) {
                self?.onDismiss?()
            }
        }
    }
}
