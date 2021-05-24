//
//  Notice.AllNoticeViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Notice {
    
    class AllNoticeViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            let lb = n.titleLabel
            lb.text = R.string.localizable.amongChatNoticeAllNoticeTitle()
            return n
        }()
        
        private typealias SegmentedButton = Social.ProfileLookViewController.SegmentedButton
        private lazy var segmentedButton: SegmentedButton = {
            let s = SegmentedButton()
            s.selectedIndexObservable
                .subscribe(onNext: { [weak self] (idx) in
                    guard let `self` = self else { return }
                    let offset = CGPoint(x: self.scrollView.bounds.width * CGFloat(idx), y: 0)
                    self.scrollView.setContentOffset(offset, animated: true)
                })
                .disposed(by: bag)
            return s
        }()
        
        private lazy var scrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            s.isPagingEnabled = true
            s.delegate = self
            return s
        }()
        
        private let pageIndex = BehaviorRelay(value: 0)
        
        private lazy var tabDataSoure: [(String, UnhandledNoticeStatusObservableProtocal)] = {
            
            var dataSource: [(String, UnhandledNoticeStatusObservableProtocal)] = [
                (R.string.localizable.amongChatNoticeSystem(), systemNoticeVc),
                (R.string.localizable.amongChatNoticeSocial(), socialNoticeVc)
            ]
            
            if Settings.shared.amongChatUserProfile.value?.isVerified ?? false {
                dataSource.append((R.string.localizable.amongChatNoticeGroupRequests(), groupRequestsListVc))
            }
            
            return dataSource
        }()
        
        private lazy var systemNoticeVc: NoticeListViewController = {
            let vc = NoticeListViewController()
            vc.refreshHandler = { [weak self] in
                self?.loadData()
            }
            return vc
        }()
        
        private lazy var socialNoticeVc: NoticeListViewController = {
            let vc = NoticeListViewController()
            vc.refreshHandler = { [weak self] in
                self?.loadData()
            }
            return vc
        }()
        
        private lazy var groupRequestsListVc = GroupRequestsListViewController()
        
        private var hasUnreadSocial = BehaviorRelay(value: false)
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData(initialLoad: true)
            setUpEvents()
        }
        
    }
    
}

extension Notice.AllNoticeViewController {
    
    private func setupLayout() {
        
        view.addSubviews(views: navView, segmentedButton, scrollView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        segmentedButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(60)
            maker.top.equalTo(navView.snp.bottom)
        }
        
        scrollView.snp.makeConstraints { (maker) in
            maker.top.equalTo(segmentedButton.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        segmentedButton.setTitles(titles: tabDataSoure.map({ $0.0 }))
        
        for (idx, tuple) in tabDataSoure.enumerated() {
            
            let vc = tuple.1
            
            addChild(vc)
            scrollView.addSubview(vc.view)
            vc.view.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(view)
                maker.height.equalToSuperview()
                if idx == 0 {
                    maker.leading.equalToSuperview()
                } else if idx == tabDataSoure.count - 1 {
                    maker.trailing.equalToSuperview()
                }
                
                if idx > 0,
                   let pre = tabDataSoure.safe(idx - 1)?.1 {
                    maker.leading.equalTo(pre.view.snp.trailing)
                }
                
            }
            vc.didMove(toParent: self)
            
        }
        
        scrollView.layoutIfNeeded()
        
    }
    
    private func loadData(initialLoad: Bool = false) {
        
        var hudRemoval: (() -> Void)? = nil
        if initialLoad {
            hudRemoval = self.view.raft.show(.loading, userInteractionEnabled: true)
        }
        
        NoticeManager.shared.latestNotice()
            .flatMap { (n) in
                Observable.zip(Request.peerNoticeMessge(skipMs: n?.ms ?? 0).asObservable(),
                               Request.globalNoticeMessage(skipMs: n?.ms ?? 0).asObservable())
                    .asSingle()
            }
            .map({ [weak self] (peerlist, globalList) -> [Entity.Notice] in
                
                self?.socialNoticeVc.hasUnhandledNotice.accept(peerlist.count > 0)
                
                var list = peerlist
                list.append(contentsOf: globalList)
                return list
            })
            .flatMap { (list) -> Single<Void> in
                return NoticeManager.shared.addNoticeList(list)
            }
            .flatMap({ () in
                NoticeManager.shared.noticeList()
            })
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (list) in
                
                self?.systemNoticeVc.dataSource = list.filter({ $0.fromUid == 1001 })
                self?.socialNoticeVc.dataSource = list.filter({ $0.fromUid == 1002 })
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
    private func setUpEvents() {
        
        pageIndex.subscribe(onNext: { [weak self] (idx) in
            self?.segmentedButton.updateSelectedIndex(idx)
        })
        .disposed(by: bag)
        
        Observable.combineLatest(
            tabDataSoure.map {
                $0.1.hasUnhandledNotice
            }
        )
        .map {
            $0.enumerated().map { [weak self] idx, hasUnhandledNotice in
                (hasUnhandledNotice, self?.segmentedButton.buttonOf(idx))
            }
        }
        .do(onNext: { (a) in
            
            for t in a {
                
                if t.0 {
                    t.1?.badgeOn(hAlignment: .headToTail(-2), topInset: 6.5, diameter: 13)
                } else {
                    t.1?.badgeOff()
                }
                
            }
            
        })
        .map({ $0.reduce(false, { result, element in
                            result || element.0 })
        })
        .catchErrorJustReturn(false)
        .bind(to: Settings.shared.hasUnreadNoticeRelay)
        .disposed(by: bag)
        
        Observable.merge(pageIndex.asObservable(), segmentedButton.selectedIndexObservable)
            .subscribe(onNext: { [weak self] (page) in
                guard page == 1 else { return }
                self?.socialNoticeVc.hasUnhandledNotice.accept(false)
            })
            .disposed(by: bag)

    }
    
}

extension Notice.AllNoticeViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        pageIndex.accept(Int(scrollView.contentOffset.x / scrollView.frame.size.width))
    }
    
}
