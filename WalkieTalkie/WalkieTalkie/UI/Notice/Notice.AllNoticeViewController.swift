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
        
        enum NoticeType {
            case system
            case social
            case groupRequest
            
            var title: String {
                switch self {
                case .system:
                    return R.string.localizable.amongChatNoticeSystem()
                case .social:
                    return R.string.localizable.amongChatNoticeSocial()
                case .groupRequest:
                    return R.string.localizable.amongChatNoticeGroupRequests()
                }
            }
            
        }
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_profile_back(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.text = R.string.localizable.amongChatNoticeAllNoticeTitle()
            return lb
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
        
        private var pageIndex: Int = 0 {
            didSet {
                segmentedButton.updateSelectedIndex(pageIndex)
            }
        }
        
        private let dataSet: [NoticeType] = {
            if let p = Settings.shared.amongChatUserProfile.value,
               !(p.isVerified ?? false) {
                return [.system, .social]
            } else {
                return [.system, .social, .groupRequest]
            }
        }()
        
        private lazy var systemNoticeVc = NoticeListViewController()
        private lazy var socialNoticeVc = NoticeListViewController()
        private var groupRequestsListVc: GroupRequestsListViewController!
        
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
        
        view.addSubviews(views: backBtn, titleLabel, segmentedButton, scrollView)
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(12)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
        
        segmentedButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(60)
            maker.top.equalTo(navLayoutGuide.snp.bottom)
        }
        
        scrollView.snp.makeConstraints { (maker) in
            maker.top.equalTo(segmentedButton.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        segmentedButton.setTitles(titles: dataSet.map({ $0.title }))
        
        addChild(systemNoticeVc)
        scrollView.addSubview(systemNoticeVc.view)
        systemNoticeVc.view.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(view)
            maker.height.equalToSuperview()
            maker.leading.equalToSuperview()
        }
        systemNoticeVc.didMove(toParent: self)
        systemNoticeVc.refreshHandler = { [weak self] in
            self?.loadData()
        }

        addChild(socialNoticeVc)
        scrollView.addSubview(socialNoticeVc.view)
        socialNoticeVc.view.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(view)
            maker.height.equalToSuperview()
            maker.leading.equalTo(systemNoticeVc.view.snp.trailing)
        }
        socialNoticeVc.didMove(toParent: self)
        socialNoticeVc.refreshHandler = { [weak self] in
            self?.loadData()
        }
        
        if let p = Settings.shared.amongChatUserProfile.value,
           (p.isVerified ?? false) {
            
            let groupRequestsListVc = Notice.GroupRequestsListViewController()
            
            addChild(groupRequestsListVc)
            scrollView.addSubview(groupRequestsListVc.view)
            groupRequestsListVc.view.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(view)
                maker.height.equalToSuperview()
                maker.leading.equalTo(socialNoticeVc.view.snp.trailing)
                maker.trailing.equalToSuperview()
            }
            socialNoticeVc.didMove(toParent: self)
           
            self.groupRequestsListVc = groupRequestsListVc
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
                
                self?.socialNoticeVc.hasUnreadNotice.accept(peerlist.count > 0)
                self?.systemNoticeVc.hasUnreadNotice.accept(globalList.count > 0)
                
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
        
        Observable.combineLatest(systemNoticeVc.hasUnreadNotice,
                                 socialNoticeVc.hasUnreadNotice,
                                 groupRequestsListVc?.hasUnhandledApplyObservable ?? Observable.just(false))
            .map({ [weak self] (unreadSystem, unreadSocial, unhandledGroupApply) -> [(Bool, UIView?)] in
                
                let systemTitleLabel = (self?.segmentedButton.buttonOf(0) as? UIButton)?.titleLabel
                let socialTitleLabel = (self?.segmentedButton.buttonOf(1) as? UIButton)?.titleLabel
                let requestsTitleLabel = (self?.segmentedButton.buttonOf(2) as? UIButton)?.titleLabel
                
                return [(unreadSystem, systemTitleLabel),
                        (unreadSocial, socialTitleLabel),
                        (unhandledGroupApply, requestsTitleLabel)]
            })
            .do(onNext: { (a) in
                
                for t in a {
                    
                    if t.0 {
                        t.1?.badgeOn(hAlignment: .headToTail(-2), diameter: 13)
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
    }

}

extension Notice.AllNoticeViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }
    
}
