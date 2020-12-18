//
//  AmongChat.CreateRoom.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/13.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.CreateRoom {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private typealias TopicCell = AmongChat.CreateRoom.TopicCell
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatCreateRoomTitle()
            return lb
        }()
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var codeField: ChannelNameField = {
            let f = ChannelNameField()
            f.clearButtonMode = .never
            let pStyle = NSMutableParagraphStyle()
            pStyle.alignment = .center
            
            let attP = NSAttributedString(string: R.string.localizable.amongChatCreateRoomInputPlaceholder(),
                                          attributes: [
                                            NSAttributedString.Key.font : R.font.nunitoExtraBold(size: 16) ?? UIFont.boldSystemFont(ofSize: 16),
                                            NSAttributedString.Key.foregroundColor : UIColor(hex6: 0xD8D8D8),
                                            NSAttributedString.Key.paragraphStyle : pStyle
                                          ])
            f.attributedPlaceholder = attP
            f.font = R.font.nunitoExtraBold(size: 16)
            f.keyboardType = .asciiCapable
            f.backgroundColor = .white
            f.layer.cornerRadius = 24
            f.textAlignment = .center
            return f
        }()
        
        private lazy var topicTable: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(TopicCell.self, forCellReuseIdentifier: NSStringFromClass(TopicCell.self))
            tb.backgroundColor = .clear
            tb.separatorStyle = .none
            tb.rowHeight = 60
            tb.dataSource = self
            tb.delegate = self
            topicHeaderView.bounds = CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width, height: 57))
            tb.tableHeaderView = topicHeaderView
            tb.keyboardDismissMode = .onDrag
            return tb
        }()
        
        private lazy var topicHeaderView: UIView = {
            let v = UIView()
            let icon = UIImageView(image: R.image.ac_topic_hot())
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatCreateRoomTopicTitle()
            
            v.addSubviews(views: icon, lb)
            
            icon.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(40)
                maker.width.height.equalTo(20)
                maker.top.equalToSuperview()
            }
            
            lb.snp.makeConstraints { (maker) in
                maker.left.equalTo(icon.snp.right).offset(8)
                maker.top.equalToSuperview()
                maker.right.equalToSuperview().inset(40)
            }
            
            return v
        }()
        
        private lazy var confirmButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.setTitle(R.string.localizable.amongChatCreateRoomConfirmBtn(""), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var privateStateLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatCreateRoomPrivate()
            return lb
        }()
        
        private lazy var privateStateSwitch: UISwitch = {
            let sw = UISwitch()
            sw.isOn = false
            sw.onTintColor = UIColor(hexString: "#FFF000")
            sw.backgroundColor = UIColor(hexString: "#101017")
            sw.layer.cornerRadius = sw.bounds.height / 2
            return sw
        }()
        
        var joinChannel: (String, Bool) -> Void = { _, _ in }
        
        typealias TopicViewModel = AmongChat.CreateRoom.TopicViewModel
        private lazy var topicDataSource: [TopicViewModel] = AmongChat.Topic.allCases.map { TopicViewModel(with: $0) }
                
        // MARK: -
                
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            view.endEditing(true)
        }
    }
    
}

extension AmongChat.CreateRoom.ViewController {
    
    // MARK: - UI action
    
    @objc
    private func onBackBtn() {
        dismiss(animated: true)
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
        
        createRoom(with: name)
//        joinBlock()
    }
}

extension AmongChat.CreateRoom.ViewController {
    
    private func setupLayout() {
        
        view.addSubviews(views: backBtn, titleLabel, codeField, topicTable, privateStateLabel, privateStateSwitch, confirmButton)
        
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
        
        topicTable.snp.makeConstraints { (maker) in
            maker.top.equalTo(codeField.snp.bottom).offset(40)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(privateStateSwitch.snp.top).offset(-40)
        }
        
        privateStateSwitch.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(40)
            maker.bottom.equalTo(confirmButton.snp.top).offset(-20)
        }
        
        privateStateLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(40)
            maker.centerY.equalTo(privateStateSwitch)
        }
        
        confirmButton.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(40)
            maker.height.equalTo(48)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-45)
        }
        
    }
    
    private func createRoom(with name: String) {
        
        view.endEditing(true)
        
        typealias Topic = AmongChat.Topic
                
        var roomProto = Entity.RoomProto()
        roomProto.state = privateStateSwitch.isOn ? .private : .public
        
        if let topic = Topic(rawValue: name) {
            roomProto.topicId = topic
        } else {
            roomProto.topicId = .chilling
            roomProto.note = name
        }
        
        let hudRemoval = view.raft.show(.loading)
        let _ = Request.createRoom(roomProto)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { (room) in
                // TODO: - 创建房间成功
                cdPrint("")
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text("failed to create room"))
            })
    }
}

extension AmongChat.CreateRoom.ViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topicDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TopicCell.self), for: indexPath)
        if let topicCell = cell as? TopicCell,
              let topic = topicDataSource.safe(indexPath.row) {
            topicCell.bindViewModel(topic)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let topic = topicDataSource.safe(indexPath.row) else {
            return
        }
        
        createRoom(with: topic.topic.rawValue)
    }

}
