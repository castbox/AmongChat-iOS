//
//  AmongChat.Home.CreateRoomViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/13.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class CreateRoomViewController: WalkieTalkie.ViewController {
        // MARK: -
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 24)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatHomeCreateRoomTitle()
            return lb
        }()
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.backNor()?.withRenderingMode(.alwaysTemplate), for: .normal)
            btn.tintColor = .white
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var codeField: ChannelNameField = {
            let f = ChannelNameField()
            f.clearButtonMode = .never
            f.placeholder = R.string.localizable.amongChatHomeCreateRoomInputPlaceholder()
            f.font = R.font.nunitoBold(size: 17)
            f.keyboardType = .asciiCapable
            f.backgroundColor = .white
            f.layer.cornerRadius = 24
            return f
        }()
        
        private lazy var confirmButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.setTitle(R.string.localizable.amongChatHomeCreateRoomConfirmBtn(""), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var stateLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 24)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatHomeCreateRoomPrivate()
            return lb
        }()
        
        private lazy var stateSwitch: UISwitch = {
            let sw = UISwitch()
            sw.isOn = false
            sw.onTintColor = UIColor(hexString: "#FFF000")
            sw.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.3)
            sw.layer.cornerRadius = sw.bounds.height / 2
            sw.addTarget(self, action: #selector(onPrivateAttSwitch(_:)), for: .primaryActionTriggered)
            return sw
        }()
        
        var joinChannel: (String, Bool) -> Void = { _, _ in }
        
        // MARK: -
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvents()
        }
        
    }
    
}

extension AmongChat.Home.CreateRoomViewController {
    
    // MARK: - UI action
    
    @objc
    private func onBackBtn() {
        dismiss(animated: true)
    }
    
    @objc
    private func onPrivateAttSwitch(_ sender: UISwitch) {
        
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
            self.dismiss(animated: true)
        }
        
        joinBlock()
    }
}

extension AmongChat.Home.CreateRoomViewController {
    
    private func setupLayout() {
        
        view.addSubviews(views: backBtn, titleLabel, codeField, stateLabel, stateSwitch, confirmButton)
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(60)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
                
        codeField.snp.makeConstraints { (maker) in
            maker.top.equalTo(navLayoutGuide.snp.bottom).offset(20)
            maker.left.right.equalToSuperview().inset(40)
            maker.height.equalTo(48)
        }
        
        stateSwitch.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(40)
            maker.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }
        
        stateLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(40)
            maker.centerY.equalTo(stateSwitch)
        }
        
        confirmButton.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(40)
            maker.height.equalTo(48)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-45)
        }
        
    }
    
    private func setupEvents() {
        
    }
}
