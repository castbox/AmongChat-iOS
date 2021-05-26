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
            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 0, right: hInset)
            return layout
        }()
        
        private lazy var videoCollectionView: UICollectionView = {
            let v = UICollectionView(frame: .zero, collectionViewLayout: videoCollectionViewFlowLayout)
            v.register(cellWithClazz: VideoCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private let mediaManager = VideoMediaManager()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            mediaManager.resetCachedAssets()
            PHPhotoLibrary.shared().register(self)
            
            setUpLayout()
        }
        
        deinit {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            mediaManager.updateCachedAssets(in: videoCollectionView, cellSize: videoCollectionViewFlowLayout.itemSize)
        }
        
    }
    
}

extension Feed.VideoLibraryViewController {
    
    private func setUpLayout() {
        view.addSubview(videoCollectionView)
        videoCollectionView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
}

extension Feed.VideoLibraryViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaManager.fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClazz: VideoCell.self, for: indexPath)
        let asset = mediaManager.fetchResult.object(at: indexPath.item)
        cell.configCell(with: asset, imageOb: mediaManager.requestImage(for: asset))
        return cell
    }
}

extension Feed.VideoLibraryViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let asset = mediaManager.fetchResult.object(at: indexPath.item)
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
        
        let asset = mediaManager.fetchResult.object(at: selectedIndex)
        
        return mediaManager.exportVideo(for: asset)
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension Feed.VideoLibraryViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: mediaManager.fetchResult)
        else { return }
        
        // Change notifications may originate from a background queue.
        // As such, re-dispatch execution to the main queue before acting
        // on the change, so you can update the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            mediaManager.fetchResult = changes.fetchResultAfterChanges
            // If we have incremental changes, animate them in the collection view.
            if changes.hasIncrementalChanges {
                let collectionView = self.videoCollectionView
                // Handle removals, insertions, and moves in a batch update.
                videoCollectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
                // We are reloading items after the batch update since `PHFetchResultChangeDetails.changedIndexes` refers to
                // items in the *after* state and not the *before* state as expected by `performBatchUpdates(_:completion:)`.
                if let changed = changes.changedIndexes, !changed.isEmpty {
                    collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                }
            } else {
                // Reload the collection view if incremental changes are not available.
                videoCollectionView.reloadData()
            }
            mediaManager.resetCachedAssets()
        }
    }
}
