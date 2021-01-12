//
//  AmongChat.Home.TopicsViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import NotificationBannerSwift

extension AmongChat.Home {
    
    class NavigationBar: UIView {
        private lazy var profileBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_profile(), for: .normal)
            btn.addTarget(self, action: #selector(onProfileBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var bannerIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_home_banner())
            return i
        }()
        
        private lazy var createRoomBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_create(), for: .normal)
            btn.addTarget(self, action: #selector(onCreateRoomBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private let bag = DisposeBag()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            Settings.shared.amongChatAvatarListShown.replay()
                .subscribe(onNext: { [weak self] (ts) in
                    if let _ = ts {
                        self?.profileBtn.redDotOff()
                    } else {
                        self?.profileBtn.redDotOn(rightOffset: 0, topOffset: 0)
                    }
                })
                .disposed(by: bag)
        }
        
        private func configureSubview() {
            addSubviews(views: profileBtn, bannerIV, createRoomBtn)
            
            profileBtn.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(42)
                maker.left.equalToSuperview().inset(20)
                maker.bottom.equalTo(-10.5)
            }
            
            createRoomBtn.snp.makeConstraints { (maker) in
                maker.right.equalToSuperview().inset(20)
                maker.width.height.equalTo(42)
                maker.centerY.equalTo(profileBtn)
            }
            
            bannerIV.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(profileBtn)
                maker.centerX.equalToSuperview()
            }
            

        }
        
        @objc
        private func onProfileBtn() {
            Routes.handle("/profile")
        }
        
        @objc
        private func onCreateRoomBtn() {
            Routes.handle("/createRoom")
        }
        
    }
    
    class TopicsViewController: WalkieTalkie.ViewController {
        
        // MARK: - members
        
        private typealias TopicCell = AmongChat.Home.TopicCell
        private typealias TopicViewModel = AmongChat.Home.TopicViewModel
        private lazy var navigationView = NavigationBar()
            
        private lazy var topicCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let hwRatio: CGFloat = 156.0 / 335.0
            let cellWidth = UIScreen.main.bounds.width - hInset * 2
            let cellHeight = cellWidth * hwRatio
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumLineSpacing = 27
            layout.sectionInset = UIEdgeInsets(top: 27, left: hInset, bottom: Frame.Height.safeAeraBottomHeight, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(TopicCell.self, forCellWithReuseIdentifier: NSStringFromClass(TopicCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private var hudRemoval: (() -> Void)? = nil
        
        private lazy var topicsDataSource: [TopicViewModel] = {
            return Settings.shared.amongChatHomeSummary.value?.topicList.map({ TopicViewModel(with: $0) }) ?? []
        }()
        {
            didSet {
                topicCollectionView.reloadData()
            }
        }
        
        override var screenName: Logger.Screen.Node.Start {
            return .home
        }
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        override var contentScrollView: UIScrollView? {
            topicCollectionView
        }
        
        //MARK: - inherited
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
        
    }
    
}

extension AmongChat.Home.TopicsViewController {

    //MARK: - UI Action
    
}

extension AmongChat.Home.TopicsViewController {
    
    // MARK: -
    
    private func setupLayout() {
                
        view.addSubviews(views: navigationView, topicCollectionView)
        
        navigationView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(62 + Frame.Height.safeAeraTopHeight)
        }
        
        topicCollectionView.snp.makeConstraints { (maker) in
            maker.top.equalTo(navigationView.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
    }
    
    private func setupEvent() {
        
        Observable.combineLatest(
            Observable<Bool>.merge(
                rx.viewWillAppear.map({ _ in true }),
                rx.viewDidDisappear.map({ _ in false })
            ),
            Observable<Void>.merge(
                rx.viewWillAppear.map({ _ in }),
                NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).map({ _ in })
            )
        )
            .filter({ visible, _ in
                return visible
            })
            .throttle(.seconds(30), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (_) in
                self?.fetchSummaryData()
            })
            .disposed(by: bag)
                
        rx.viewWillAppear
            .subscribe(onNext: { [weak self] (_) in
                self?.topicCollectionView.setContentOffset(.zero, animated: false)
            })
            .disposed(by: bag)
    }
    
    private func fetchSummaryData() {
        var hudRemoval: Raft.RemoveBlock? = nil
        if topicsDataSource.count == 0 {
           hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        }
        
        Request.summary()
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (summary) in
                
                guard let s = summary else {
                    return
                }
                
                self?.topicsDataSource = s.topicList.map({ TopicViewModel(with: $0) })
                
                cdPrint("")
            }, onError: { [weak self] (error) in
                guard self?.topicsDataSource.count == 0 else {
                    return
                }
                let v = AmongChat.Home.LoadErrorView()
                self?.view.addSubview(v)
                v.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                v.showUp { [weak self, weak v] in
                    v?.removeFromSuperview()
                    self?.fetchSummaryData()
                }
                
                cdPrint("")
            })
            .disposed(by: bag)
    }
}

extension AmongChat.Home.TopicsViewController: UICollectionViewDataSource {

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topicsDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TopicCell.self), for: indexPath)
        if let cell = cell as? TopicCell,
           let topic = topicsDataSource.safe(indexPath.item) {
            cell.bindViewModel(topic)
        }
        return cell
    }

}

extension AmongChat.Home.TopicsViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let topic = topicsDataSource.safe(indexPath.item) {
            enterRoom(topicId: topic.topic.topicId, logSource: .matchSource)
        }
    }
    
}

extension UIViewController {
    func showKickedAlert(with role: ChatRoom.KickOutMessage.Role) {
        showAmongAlert(title: role.alertTitle, message: nil, cancelTitle: nil, confirmTitle: R.string.localizable.alertOk())
    }
}
