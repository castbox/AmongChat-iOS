//
//  Conversation.InteractiveMessageController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import SwiftyUserDefaults

extension Conversation {
    
    struct InteractiveMessageCellViewModel {
        let msg: Entity.DMInteractiveMessage
        let emote: URL?
        let timeString: String?
        let height: CGFloat
        let isRead: Bool
        
        init(msg: Entity.DMInteractiveMessage, updateTime: Double) {
            self.msg = msg
            
            self.timeString = msg.createTime.timeFormattedForConversationList()
            
            let contentHeight: CGFloat
            let maxWidth = Frame.Screen.width - 100
            let contentTopEdge: CGFloat = 8
            if !msg.text.isEmpty {
                contentHeight = msg.text.boundingRect(with: CGSize(width: maxWidth, height: 1000), font: R.font.nunitoBold(size: 14)!).height + contentTopEdge
            } else if !msg.emoteIds.isEmpty {
                contentHeight = 32 + contentTopEdge
            } else {
                contentHeight = 0
            }
            emote = Settings.shared.globalSetting.value?.feedEmotes.first(where: { $0.id == (msg.emoteIds.first ?? "") })?.img
            isRead = updateTime >= msg.opTime
            self.height = 111 + contentHeight
        }
        
    }
    
    class InteractiveMessageController: WalkieTalkie.ViewController {
        
        private lazy var navView: InteractiveNavigationBar = {
            let n = InteractiveNavigationBar()
            n.leftBtn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.navigationController?.popViewController()
                }).disposed(by: bag)
            n.selectHandler = { [weak self] type in
                self?.opType = type
            }
            return n
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(nibWithCellClass: InteractiveMsgTableCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var dataSource: [InteractiveMessageCellViewModel] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        
        private var updateTime: Double {
            get { Defaults[\.dmInteractiveMsgUpdateTime] }
            set { Defaults[\.dmInteractiveMsgUpdateTime] = newValue }
        }
        
        var opType: Entity.DMInteractiveMessage.OpType? {
            didSet {
                loadData()
            }
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            updateTime = dataSource.first?.msg.opTime ?? 0
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
        }
        
        private func setupLayout() {
            
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            view.addSubviews(views: navView)
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(navView.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            tableView.pullToRefresh { [weak self] in
                self?.loadData()
            }
            tableView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            Request.interactiveMsgs(opType, skipMs: 0)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.dataSource = data.list.map { InteractiveMessageCellViewModel(msg: $0, updateTime: self.updateTime) }
                    if self.dataSource.isEmpty {
                        self.addNoDataView(R.string.localizable.amongChatNoticeEmptyTip(), image: R.image.ac_among_apply_empty())
                    } else {
                        self.removeNoDataView()
                    }
                    self.tableView.endLoadMore(data.more)
                }, onError: { [weak self](error) in
                    removeBlock()
                    self?.addErrorView({ [weak self] in
                        self?.loadData()
                    })
                }).disposed(by: bag)
        }
        
        private func loadMore() {
            let removeBlock = view.raft.show(.loading)
            let skipMS = dataSource.last?.msg.opTime ?? 0
            Request.interactiveMsgs(opType, skipMs: skipMS)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let `self` = self else { return }
                    let list = data.list.map { InteractiveMessageCellViewModel(msg: $0, updateTime: self.updateTime) }
                    var origenList = self.dataSource
                    list.forEach({ origenList.append($0)})
                    self.dataSource = origenList
                    self.tableView.endLoadMore(data.more)
                }, onError: { (error) in
                    removeBlock()
                }).disposed(by: bag)
        }
    }
}

// MARK: - UITableView
extension Conversation.InteractiveMessageController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: InteractiveMsgTableCell.self)
        
        if let item = dataSource.safe(indexPath.row) {
            cell.configView(with: item)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return dataSource.safe(indexPath.row)?.height ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let msg = dataSource.safe(indexPath.row) {
            
        }
    }
}
