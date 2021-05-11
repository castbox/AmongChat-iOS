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
        
//        private lazy var collectionView: UICollectionView = {
//            let layout = UICollectionViewFlowLayout()
//            layout.scrollDirection = .vertical
//            var hInset: CGFloat = 20
//            var columns: Int = 1
//            let interitemSpacing: CGFloat = 20
//            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 84)
//            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 0, right: hInset)
//            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
//            v.register(nibWithCellClass: ConversationListCell.self)
//            v.showsVerticalScrollIndicator = false
//            v.showsHorizontalScrollIndicator = false
//            v.dataSource = self
//            v.delegate = self
//            v.backgroundColor = .clear
//            v.alwaysBounceVertical = true
//            return v
//        }()
        
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
                
//        var dataSource: [Entity.Notice] = [] {
//            didSet {
////                noticeVMList = dataSource.enumerated().map({ [weak self] (idx, notice) in
////                    NoticeViewModel(with: notice) {
////                        self?.noticeListView.reloadItems(at: [IndexPath(item: idx, section: 0)])
////                    }
////
////                })
//            }
//        }
        
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
//            cell.configView(with: user, isFollowing: false, isSelf: false)
//            cell.updateFollowData = { [weak self] (follow) in
//                guard let `self` = self else { return }
//                self.userList[indexPath.row].isFollowed = follow
//                self.addLogForFollow(with: self.userList[indexPath.row].uid)
//            }
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
        return 0.001
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
            handler(true)
            self?.deleteAllHistory(for: item.fromUid)
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

extension AmongChat.Home.ConversationListController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = dataSource.safe(indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: ConversationListCell.self, for: indexPath)
        
        cell.bind(item)
//        switch notice.notice.message.messageType {
//        case .TxtMsg, .ImgMsg, .ImgTxtMsg, .TxtImgMsg:
//            cell = collectionView.dequeueReusableCell(withClass: ConversationListCell.self, for: indexPath)
//            if let cell = cell as? ConversationListCell {
////                cell.bindNoticeData(notice)
//            }

//        case .SocialMsg:
//            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SocialMessageCell.self), for: indexPath)
//
//            if let cell = cell as? SocialMessageCell {
//                cell.bindNoticeData(notice)
//            }
//
//        }
        
        return cell
    }
}

extension AmongChat.Home.ConversationListController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        DMManager.shared.clearAllMessage(of: uid)
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
//            maker.leading.greaterThanOrEqualToSuperview().offset(40)
//            maker.top.equalTo(navigationView.snp.bottom)
        }
        
        listView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(navigationView.snp.bottom)
        }
    }
    
}
