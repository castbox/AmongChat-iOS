//
//  Feed.SelectTopicViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

extension Feed {
    
    class SelectTopicViewController: WalkieTalkie.ViewController {
        
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
            lb.text = R.string.localizable.feedPostTitle()
            return n
        }()
        
        private lazy var thumbnailView: VideoThumbnailView = {
            let v = VideoThumbnailView()
            videoThumbnail.subscribe(onSuccess: { (image) in
                v.image = image
            })
            .disposed(by: bag)
            v.layer.cornerRadius = 12
            v.clipsToBounds = true
            return v
        }()
        
        private lazy var videoAsset: AVAsset = {
            let asset = AVAsset(url: videoURL)
            return asset
        }()
        
        private lazy var videoThumbnail: Single<UIImage?> = {
            
            return Observable.create { [weak self] (subscriber) -> Disposable in
                guard let `self` = self else {
                    return Disposables.create()
                }
                DispatchQueue.global().async {
                    let assetImgGenerate = AVAssetImageGenerator(asset: self.videoAsset)
                    assetImgGenerate.appliesPreferredTrackTransform = true
                    let time = CMTimeMakeWithSeconds(Float64(1), preferredTimescale: 100)
                    do {
                        let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                        let thumbnail = UIImage(cgImage: img)
                        subscriber.onNext(thumbnail)
                        subscriber.onCompleted()
                    } catch let error {
                        subscriber.onError(error)
                    }
                }
                return Disposables.create()
            }
            .asSingle()
            .observeOn(MainScheduler.asyncInstance)
        }()
        
        private typealias TopiceHeader = Feed.VideoLibraryViewController.DurationTipHeader
        private lazy var topicCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 0
            var columns: Int = 1
            let interitemSpacing: CGFloat = 20
            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight: CGFloat = 40
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interitemSpacing
            layout.minimumLineSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: 16, left: hInset, bottom: 0, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(cellWithClazz: TopicCell.self)
            v.register(TopiceHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(TopiceHeader.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private lazy var bottomGradientView: FansGroup.Views.BottomGradientButton = {
            let v = FansGroup.Views.BottomGradientButton()
            v.button.setTitle(R.string.localizable.amongChatCreateRoomCreate(), for: .normal)
            v.button.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.post()
                })
                .disposed(by: bag)
            v.button.isEnabled = false
            return v
        }()
        
        private lazy var topicDataSource: [Entity.GlobalSetting.Topic] = Settings.shared.globalSetting.value?.feedTopics ?? [] {
            didSet {
                topicCollectionView.reloadData()
            }
        }
        
        private let videoURL: URL
        
        init(videoURL: URL) {
            self.videoURL = videoURL
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            topicCollectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: bottomGradientView.bounds.height, right: 0)
        }
        
    }
    
}

extension Feed.SelectTopicViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, thumbnailView, topicCollectionView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        thumbnailView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
            maker.top.equalTo(navView.snp.bottom).offset(24)
            maker.height.equalTo(thumbnailView.snp.width).multipliedBy(189.0 / 335.0)
        }
        
        topicCollectionView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(thumbnailView.snp.bottom).offset(20)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setUpEvents() {
        
        topicCollectionView.rx.itemSelected
            .do(onNext: { [weak self] (idx) in
                Logger.Action.log(.feeds_create_topic_clk, categoryValue: self?.topicDataSource.safe(idx.item)?.topicId)
            })
            .map({ _ in true })
            .bind(to: bottomGradientView.button.rx.isEnabled)
            .disposed(by: bag)
        
    }
        
    private func post() {
        
        let hudRemoval: (() -> Void) = view.raft.show(.loading, userInteractionEnabled: false)
        
        Observable.combineLatest(uploadThumbnail().asObservable(), uploadVideo().asObservable())
            .flatMap { [weak self] (thumbnailUrl, videoUrl) -> Observable<Void> in
                guard let `self` = self else {
                    return Observable.empty()
                }
                return self.createFeed(thumbnailUrl: thumbnailUrl, videoUrl: videoUrl).asObservable()
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (_) in
                hudRemoval()
                self?.navigationController?.popToRootViewController(animated: true)
            }, onError: { [weak self] (error) in
                hudRemoval()
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
        
        Logger.Action.log(.feeds_create_topic_done)
    }
    
    private func uploadThumbnail() -> Single<String> {
        return videoThumbnail.flatMap { image -> Single<String> in
            guard let image = image else {
                return Single.just("")
            }
            return Request.uploadPng(image: image)
        }
    }
    
    private func uploadVideo() -> Single<String> {
        do {
            let data = try Data(contentsOf: videoURL)
            return Request.uploadData(data, ext: "mp4", mimeType: "video/mp4", type: .video)
        } catch let error {
            return Single.error(error)
        }
    }
    
    private func createFeed(thumbnailUrl: String, videoUrl: String) -> Single<Void> {
        
        guard let selectedIdx = topicCollectionView.indexPathsForSelectedItems?.first?.item,
              let topic = topicDataSource.safe(selectedIdx) else {
            
            return Single.error(MsgError.default)
        }
        
        let duration = videoAsset.duration.value / Int64(videoAsset.duration.timescale)
        
        let proto = Entity.FeedProto(img: thumbnailUrl, url: videoUrl, duration: duration, topic: topic.topicId)
        
        return Request.createFeed(proto: proto)
        
    }
}

extension Feed.SelectTopicViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topicDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClazz: TopicCell.self, for: indexPath)
        
        if let topic = topicDataSource.safe(indexPath.item) {
            cell.configCell(with: topic)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(TopiceHeader.self.self), for: indexPath)
            if let header = header as? TopiceHeader {
                header.icon.image = R.image.ac_feed_topic_tip()
                header.titleLabel.text = R.string.localizable.feedChooseTopicTitle()
            }
            return header
        default:
            return UICollectionReusableView()
        }
        
    }
    
}

extension Feed.SelectTopicViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: Frame.Screen.bounds.width, height: 20)
    }
    
}
