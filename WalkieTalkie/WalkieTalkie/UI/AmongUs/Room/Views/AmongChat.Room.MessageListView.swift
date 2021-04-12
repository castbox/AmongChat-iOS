//
//  AmongChat.Room.MessageListView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Room {
    class MessageListView: UIView {
        
        var messageEventHandler: () -> Void = { }
        weak var dataSource: MessageDataSource?
        
        private lazy var messageBackgroundLayer = CAGradientLayer()
        private lazy var messageBackgroundView: UIView = {
            let view = UIView()
            view.backgroundColor = .clear
            view.layer.insertSublayer(messageBackgroundLayer, at: 0)
            return view
        }()
        private lazy var messageView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(AmongChat.Room.MessageTextCell.self, forCellReuseIdentifier: NSStringFromClass(AmongChat.Room.MessageTextCell.self))
            tb.backgroundColor = .clear
            tb.dataSource = self
            tb.delegate = self
            tb.separatorStyle = .none
            tb.rowHeight = UITableView.automaticDimension
            tb.estimatedRowHeight = 80
            
            return tb
        }()
        
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            configureSubview()
            bindSubviewEvent()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            messageBackgroundLayer.frame = messageBackgroundView.bounds
        }
        
        func bind(dataSource: MessageDataSource) {
            dataSource.messageListUpdateEventHandler = { [weak self] in
                guard let `self` = self else { return }
                let contentHeight = self.messageView.contentSize.height
                let height = self.messageView.bounds.size.height
                let contentOffsetY = self.messageView.contentOffset.y
                let bottomOffset = contentHeight - contentOffsetY
                //            self.newMessageButton.isHidden = true
                // 消息不足一屏
                if contentHeight < height {
                    self.messageView.reloadData()
                } else {// 超过一屏
                    if floor(bottomOffset) - floor(height) < 40 {// 已经在底部
                        let rows = self.messageView.numberOfRows(inSection: 0)
                        let newRow = dataSource.messages.count
                        guard newRow > rows else { return }
                        let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                        self.messageView.beginUpdates()
                        self.messageView.insertRows(at: indexPaths, with: .none)
                        self.messageView.endUpdates()
                        if let endPath = indexPaths.last {
                            self.messageView.scrollToRow(at: endPath, at: .bottom, animated: true)
                        }
                    } else {
                        //                    if self.messageView.numberOfRows(inSection: 0) <= 2 {
                        //                        self.newMessageButton.isHidden = true
                        //                    } else {
                        //                        self.newMessageButton.isHidden = false
                        //                    }
                        self.messageView.reloadData()
                    }
                }
            }
            self.dataSource = dataSource
        }
        
        private func bindSubviewEvent() {
            
        }
        
        private func configureSubview() {
            messageBackgroundLayer.startPoint = CGPoint(x: 0, y: 0)
            messageBackgroundLayer.endPoint = CGPoint(x: 0, y: 1)
            messageBackgroundLayer.colors = [UIColor.black.alpha(0).cgColor, UIColor.black.alpha(0.6).cgColor]
            
            addSubviews(views: messageBackgroundView, messageView)
            //            let messageViewTopEdge = Frame.Height.deviceDiagonalIsMinThan4_7 ? 0 : 17
            messageView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                //                maker.top.equalTo(seatView.snp.bottom).offset(messageViewTopEdge)
                //                maker.bottom.equalTo(bottomBar.snp.top).offset(-10)
                //                maker.left.right.equalToSuperview()
            }
            
            messageBackgroundView.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.bottom.equalToSuperview().offset(10 + 42 + Frame.Height.safeAeraBottomHeight + 5)
            }
            
        }
        
        func messageListScrollToBottom() {
            let rows = self.messageView.numberOfRows(inSection: 0)
            if rows > 0 {
                let endPath = IndexPath(row: rows - 1, section: 0)
                self.messageView.scrollToRow(at: endPath, at: .bottom, animated: true)
            }
        }
    }
}


extension AmongChat.Room.MessageListView: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.messages.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(AmongChat.Room.MessageTextCell.self), for: indexPath)
        
        if let cell = cell as? AmongChat.Room.MessageTextCell,
           let model = dataSource?.messages.safe(indexPath.row) {
            cell.configCell(with: model)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if let message = dataSource?.messages.safe(indexPath.row) as? MessageListable {
            message.rawContent?.copyToPasteboardWithHaptic()
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
}

