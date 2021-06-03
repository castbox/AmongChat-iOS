//
//  Feed.VideoLibraryViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/25.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import RxSwift
import RxCocoa

extension Feed {
    
    class VideoLibraryViewController: WalkieTalkie.ViewController {
        
        private let videoCollectionViewFlowLayout: UICollectionViewFlowLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = Frame.horizontalBleedWidth
            var columns: Int = 3
            let interitemSpacing: CGFloat = 8
            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight: CGFloat = cellWidth
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interitemSpacing
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 17, left: hInset, bottom: 0, right: hInset)
            return layout
        }()
        
        private lazy var emptyView: FansGroup.Views.EmptyDataView = {
            let v = FansGroup.Views.EmptyDataView()
            v.titleLabel.text = R.string.localizable.feedLibraryVideoEmpty()
            v.isHidden = true
            return v
        }()
        
        private lazy var queryAccessLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoSemiBold(size: 14)
            l.textColor = UIColor(hex6: 0xABABAB)
            l.textAlignment = .center
            l.text = R.string.localizable.feedLibraryAccessPhotoText()
            l.numberOfLines = 0
            l.isHidden = true
            return l
        }()
        
        private lazy var gotoSettinsBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                })
                .disposed(by: bag)
            btn.setTitleColor(.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 18
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            btn.setTitle(R.string.localizable.amongChatOpenSettings(), for: .normal)
            btn.isHidden = true
            return btn
        }()

        private lazy var videoCollectionView: UICollectionView = {
            let v = UICollectionView(frame: .zero, collectionViewLayout: videoCollectionViewFlowLayout)
            v.register(cellWithClazz: VideoCell.self)
            v.register(DurationTipHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(DurationTipHeader.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            v.contentInset = UIEdgeInsets(top: 13, left: 0, bottom: 0, right: 0)
            return v
        }()
        
        private let mediaManager = VideoMediaManager()
        
        private var fetchResult: PHFetchResult<PHAsset>! {
            didSet {
                videoCollectionView.reloadData()
                switch PHPhotoLibrary.authorizationStatus() {
                case .restricted, .denied:
                    emptyView.titleLabel.text = R.string.localizable.feedLibraryAccessPhotoTitle()
                    emptyView.iconIV.image = R.image.ac_feed_library_empty()
                    emptyView.isHidden = false
                    queryAccessLabel.isHidden = false
                    gotoSettinsBtn.isHidden = false
                    
                default:
                    emptyView.titleLabel.text = R.string.localizable.feedLibraryVideoEmpty()
                    emptyView.iconIV.image = R.image.ac_among_apply_empty()
                    emptyView.isHidden = (fetchResult.count > 0)
                    queryAccessLabel.isHidden = true
                    gotoSettinsBtn.isHidden = true
                }
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined:
                PhotoManager.shared.requestAuthorization({ (status) in
                    
                })
            default:
                ()
            }
            
            mediaManager.resetCachedAssets()
            
            setUpLayout()
            setUpEvents()
        }
                
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            mediaManager.updateCachedAssets(in: videoCollectionView, cellSize: videoCollectionViewFlowLayout.itemSize)
        }
        
    }
    
}

extension Feed.VideoLibraryViewController {
    
    private func setUpLayout() {
        view.addSubviews(views: videoCollectionView, emptyView, queryAccessLabel, gotoSettinsBtn)
        videoCollectionView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(90)
        }
        
        queryAccessLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(emptyView.snp.bottom)
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
        }
        
        gotoSettinsBtn.snp.makeConstraints { (maker) in
            maker.top.equalTo(queryAccessLabel.snp.bottom).offset(20)
            maker.height.equalTo(36)
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
        }
        
    }
    
    private func setUpEvents() {
        
        mediaManager.fetchResultObservable
            .subscribe(onNext: { [weak self] (result) in
                self?.fetchResult = result
            })
            .disposed(by: bag)
    }
    
}

extension Feed.VideoLibraryViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClazz: VideoCell.self, for: indexPath)
        let asset = fetchResult.object(at: indexPath.item)
        cell.configCell(with: asset, imageOb: mediaManager.requestImage(for: asset))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(DurationTipHeader.self), for: indexPath)
        default:
            return UICollectionReusableView()
        }

    }
    
}

extension Feed.VideoLibraryViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: Frame.Screen.bounds.width, height: 20)
    }
    
}

extension Feed.VideoLibraryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let asset = fetchResult.object(at: indexPath.item)
        return asset.duration <= 60
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        mediaManager.updateCachedAssets(in: videoCollectionView, cellSize: videoCollectionViewFlowLayout.itemSize)
    }
}

extension Feed.VideoLibraryViewController: FeedVideoSelective {
    
    var hasSelected: Observable<Void> {
        return videoCollectionView.rx.itemSelected.map({ _ in }).asObservable()
    }
    
    func clearSelection() {
        
        videoCollectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
            videoCollectionView.deselectItem(at: indexPath, animated: false)
        })
        
    }
    
    func getVideo() -> Observable<URL> {
        
        guard let selectedIndex = videoCollectionView.indexPathsForSelectedItems?.first?.item else {
            return Observable.empty()
        }
        
        let asset = fetchResult.object(at: selectedIndex)
        
        return mediaManager.exportVideo(for: asset)
    }
}

