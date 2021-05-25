//
//  Feed.VideoMediaManager.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/25.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import Photos
import PhotosUI
import RxSwift

extension Feed {
    
    class VideoMediaManager: NSObject {
        
        lazy var fetchResult: PHFetchResult<PHAsset> = {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            let r = PHAsset.fetchAssets(with: options)
            return r
        }()
        
        let imageManager = PHCachingImageManager()
        
        private lazy var previousPreheatRect = CGRect.zero
        
        private var thumbnailSize: CGSize = .zero
        
    }
    
}

extension Feed.VideoMediaManager {
    
    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    /// - Tag: UpdateAssets
    func updateCachedAssets(in videoCollectionView: UICollectionView, cellSize: CGSize) {
        
        thumbnailSize = {
            let scale = UIScreen.main.scale
            return CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        }()
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: videoCollectionView.contentOffset, size: videoCollectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > videoCollectionView.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in videoCollectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in videoCollectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }
    
    private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    func requestImage(for asset: PHAsset) -> Observable<UIImage?> {
        return imageManager.rx.requestImage(for: asset, targetSize: thumbnailSize)
    }
    
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

extension Reactive where Base: PHImageManager {
    
    func requestImage(for asset: PHAsset,
                      targetSize: CGSize) -> Observable<UIImage?> {
        
        return Observable<UIImage?>.create { (subscriber) -> Disposable in
            
            var requestId: PHImageRequestID?
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.resizeMode = .exact
                options.isSynchronous = true
                
                requestId = base.requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: .aspectFill,
                                              options: options) { image, _ in
                    subscriber.onNext(image)
                    subscriber.onCompleted()
                }
                
            }
            
            return Disposables.create {
                guard let requestId = requestId else { return }
                base.cancelImageRequest(requestId)
            }
            
        }
        .observeOn(MainScheduler.asyncInstance)
        
    }
    
}
