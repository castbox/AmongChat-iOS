//
//  ConversationListController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension AmongChat.Home {
    class ConversationViewModel {
        let bag = DisposeBag()
        private var dataSource: [Entity.DMConversation] = []
        let dataSourceReplay = BehaviorRelay<[Entity.DMConversation]>(value: [])
        
        init() {
            DMManager.shared.conversactionUpdateReplay
                .startWith(nil)
                .flatMap { item -> Single<[Entity.DMConversation]> in
                    return DMManager.shared.conversations()
                }
                .do(onNext: { items in
                    let unreadCount = items.reduce(0, { $0 + $1.unreadCount })
                    Settings.shared.hasUnreadMessageRelay.accept(unreadCount > 0)
                })
                .observeOn(MainScheduler.asyncInstance)
                .bind(to: dataSourceReplay)
                .disposed(by: bag)
        }
    }
    
    class ConversationListController: WalkieTalkie.ViewController {
        
        private let viewModel = ConversationViewModel()
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        private lazy var navigationView = AmongChat.Home.NavigationBar(.notice)
        
        private lazy var listView: UITableView = {
            let v = UITableView(frame: .zero, style: .plain)
            v.register(nibWithCellClass: ConversationTableCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.separatorStyle = .none
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private lazy var emptyView: FansGroup.Views.EmptyDataView = {
            let v = FansGroup.Views.EmptyDataView()
            v.titleLabel.text = R.string.localizable.amongChatNoticeEmptyTip()
            v.isHidden = true
            return v
        }()
        
        private let hasUnreadNotice = BehaviorRelay(value: false)
                        
        private var dataSource: [Entity.DMConversation] = [] {
            didSet {
                listView.reloadData()
                emptyView.isHidden = dataSource.count > 0
//                collectionView.endRefresh()
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            setUpLayout()
            bindSubviewEvent()
        }
        
    }
}

// MARK: - UITableView
extension AmongChat.Home.ConversationListController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: ConversationTableCell.self, for: indexPath)
        if let item = dataSource.safe(indexPath.row) {
            cell.bind(item)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 6
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete,
              let item = dataSource.safe(indexPath.item) else {
            return
        }
        deleteAllHistory(for: item.fromUid)
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = dataSource.safe(indexPath.item) else {
            return nil
        }
        let action = UIContextualAction(style: .destructive, title: R.string.localizable.amongChatDelete()) { [weak self] action, view, handler in
            guard let `self` = self else { return }
            self.showAmongAlert(title: R.string.localizable.dmDeleteHistoryAlertTitle(),
                                cancelTitle: R.string.localizable.toastCancel(),
                                confirmTitle: R.string.localizable.groupRoomYes(),
                                confirmTitleColor: "#FB5858".color(),
                                confirmAction: { [weak self] in
                                    handler(true)
                                    self?.deleteAllHistory(for: item.fromUid)
                                })
        }
        action.image = R.image.iconDmConversationDelete()
        action.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = dataSource.safe(indexPath.item) else {
            return
        }
        let vc = ConversationViewController(item)
        navigationController?.pushViewController(vc)
    }
}

extension AmongChat.Home.ConversationListController {
    
    func deleteAllHistory(for uid: String) {
        let removeBlock = view.raft.show(.loading)
        DMManager.shared.deleteConversation(of: uid)
            .subscribe(onSuccess: { [weak self] in
                removeBlock()
//                self?.navigationController?.popViewController()
            }) { error in
                removeBlock()
            }
            .disposed(by: bag)
    }

    
    func bindSubviewEvent() {
        viewModel.dataSourceReplay
            .subscribe(onNext: { [weak self] source in
                self?.dataSource = source
            })
            .disposed(by: bag)
    }
    
    private func setUpLayout() {
        view.addSubviews(views: navigationView, emptyView, listView)
        
        navigationView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        
        emptyView.snp.makeConstraints { (maker) in
            maker.center.equalTo(listView.snp.center)
        }
        
        listView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(navigationView.snp.bottom)
        }
    }
    
}
