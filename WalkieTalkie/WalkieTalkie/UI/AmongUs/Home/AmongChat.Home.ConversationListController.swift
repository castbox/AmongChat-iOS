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
        
        private lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            var columns: Int = 1
            let interitemSpacing: CGFloat = 20
//            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
//            let cellHeight: CGFloat = 64
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 84)
//            layout.minimumInteritemSpacing = interitemSpacing
//            layout.minimumLineSpacing = 36
            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 0, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(nibWithCellClass: ConversationListCell.self)
//            v.register(SystemMessageCell.self, forCellWithReuseIdentifier: NSStringFromClass(SystemMessageCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
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
                collectionView.reloadData()
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

extension AmongChat.Home.ConversationListController: UICollectionViewDelegateFlowLayout {
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//
//        guard let notice = dataSource.safe(indexPath.item) else {
//            return .zero
//        }
//
//        return notice.itemsSize
//    }
    
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
    
    func bindSubviewEvent() {
        viewModel.dataSourceReplay
            .subscribe(onNext: { [weak self] source in
                self?.dataSource = source
            })
            .disposed(by: bag)
    }
    
    private func setUpLayout() {
        view.addSubviews(views: navigationView, emptyView, collectionView)
        
        navigationView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(navigationView.snp.bottom)
        }
        
        collectionView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(navigationView.snp.bottom)
        }
    }
    
}
