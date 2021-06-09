//
//  FansGroup.AddTopicViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/30.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import UICollectionViewLeftAlignedLayout
import RxSwift
import HWPanModal

extension FansGroup {
    
    class AddTopicViewController: WalkieTalkie.ViewController {
        
        typealias TopicCell = FansGroup.Views.GroupTopicCell
        private lazy var topicCollectionView: UICollectionView = {
            let layout = UICollectionViewLeftAlignedLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let vInset: CGFloat = 24
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(TopicCell.self, forCellWithReuseIdentifier: NSStringFromClass(TopicCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            v.backgroundColor = UIColor(hex6: 0x222222)
            return v
        }()
        
        private lazy var topBar: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            
            let bar: UIView = {
                let v = UIView()
                v.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.2)
                v.layer.cornerRadius = 2
                v.clipsToBounds = true
                return v
            }()
            
            let titleLabel: UILabel = {
                let lb = UILabel()
                lb.font = R.font.nunitoExtraBold(size: 16)
                lb.textColor = UIColor.white
                lb.text = R.string.localizable.amongChatAddTopic()
                return lb
            }()
            
            let seperatorLine: UIView = {
                let v = UIView()
                v.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.06)
                return v
            }()
            
            v.addSubviews(views: bar, titleLabel, seperatorLine)
            
            bar.snp.makeConstraints { (maker) in
                maker.top.equalTo(8)
                maker.height.equalTo(4)
                maker.width.equalTo(36)
                maker.centerX.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(28)
            }
            
            seperatorLine.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.height.equalTo(1)
            }
            
            return v
        }()
        
        var topicSelectedHandler: ((FansGroup.TopicViewModel) -> Void)? = nil
        
        typealias TopicViewModel = FansGroup.TopicViewModel
        private lazy var topicDataSource: [TopicViewModel] = Settings.shared.supportedTopics.value?.topicList.map({ TopicViewModel(with: $0) }) ?? [] {
            didSet {
                topicCollectionView.reloadData()
            }
        }
        
        private let initialSelectedTopicId: String?
        
        init(_ selectedTopicId: String? = nil) {
            initialSelectedTopicId = selectedTopicId
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .overCurrentContext
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            topBar.addCorner(with: 20, corners: [.topLeft, .topRight])
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            fetchData()
            setUpEvents()
        }
        
    }
    
}

extension FansGroup.AddTopicViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: topBar, topicCollectionView)
        
        topBar.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(66)
        }
        
        topicCollectionView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(topBar.snp.bottom)
        }
        
    }
    
    private func initialSelect() {
        guard let topicId = initialSelectedTopicId,
              let idx = topicDataSource.firstIndex(where: { $0.topic.topicId == topicId }) else {
            return
        }
        
        topicCollectionView.selectItem(at: IndexPath(item: idx, section: 0), animated: false, scrollPosition: .top)
    }
    
    private func fetchData() {
        
        let hudRemoval: (() -> Void)? = Settings.shared.supportedTopics.value?.topicList.count ?? 0 > 0 ? nil : view.raft.show(.loading, userInteractionEnabled: false)
        Request.topics()
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (s) in
                guard let summary = s else {
                    self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    return
                }
                self?.topicDataSource = summary.topicList.map({ TopicViewModel(with: $0) })
                self?.initialSelect()
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.localizedDescription))
            })
            .disposed(by: bag)        
    }
    
    private func setUpEvents() {
        rx.viewDidAppear.take(1)
            .subscribe(onNext: { (_) in
                Logger.Action.log(.group_create_add_topic_imp)
            })
            .disposed(by: bag)

    }
}

extension FansGroup.AddTopicViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topicDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TopicCell.self), for: indexPath)
        
        if let cell = cell as? TopicCell,
           let viewModel = topicDataSource.safe(indexPath.item) {
            cell.bindViewModel(viewModel)
        }
        
        return cell
    }
    
}

extension FansGroup.AddTopicViewController: UICollectionViewDelegate {
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let topic = topicDataSource.safe(indexPath.item) else {
            return
        }
        
        topicSelectedHandler?(topic)
        
        dismiss(animated: true)
        Logger.Action.log(.group_create_add_topic_clk, categoryValue: topic.topic.topicId)
    }
}

extension FansGroup.AddTopicViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let topic = topicDataSource.safe(indexPath.item) else {
            return .zero
        }
        
        return topic.itemSize
        
    }
    
}

extension FansGroup.AddTopicViewController {
    
    override func longFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .topInset, height: 0)
    }
    
    override func shortFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: Frame.Scale.height(500))
    }
    
    override func panScrollable() -> UIScrollView? {
        return topicCollectionView
    }
    
    override func allowsExtendedPanScrolling() -> Bool {
        return true
    }
    
    override func cornerRadius() -> CGFloat {
        return 20
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
}
