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
        
        private var exportedVideoURLs = [URL]()
        
        deinit {
            cdPrint("")
            clearExportedVideoFiles()
        }
        
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

extension Feed.VideoMediaManager {
    
    func exportVideo(for videoAsset: PHAsset) -> Observable<URL> {
        
        return Observable<URL>.create { [weak self] (subscriber) -> Disposable in
            
            guard let `self` = self else {
                return Disposables.create()
            }
            
            var exportSession: AVAssetExportSession?
            
            let videosOptions = PHVideoRequestOptions()
            videosOptions.isNetworkAccessAllowed = true
            videosOptions.deliveryMode = .highQualityFormat
            
            self.imageManager.requestAVAsset(forVideo: videoAsset, options: videosOptions) { asset, _, _ in
                guard let asset = asset else {
                    cdPrint("⚠️ PHCachingImageManager >>> Don't have the asset")
                    subscriber.onError(MsgError(code: -1, msg: "⚠️ PHCachingImageManager >>> Don't have the asset"))
                    return
                }
                
                let composition = AVMutableComposition()
                
                guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                      let assetTrack = asset.tracks(withMediaType: .video).first else {
                    cdPrint("Something is wrong with the asset.")
                    subscriber.onError(MsgError(code: -1, msg: "⚠️ Something is wrong with the asset."))
                    return
                }
                
                do {
                    let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                    try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
                    
                    if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
                       let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio,
                                                                               preferredTrackID: kCMPersistentTrackID_Invalid) {
                        try compositionAudioTrack.insertTimeRange(timeRange,
                                                                  of: audioAssetTrack,
                                                                  at: .zero)
                    }
                } catch let error {
                    cdPrint(error)
                    subscriber.onError(error)
                    return
                }
                
                compositionTrack.preferredTransform = assetTrack.preferredTransform
                let videoInfo = self.orientation(from: assetTrack.preferredTransform)
                
                let videoSize: CGSize
                if videoInfo.isPortrait {
                    videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
                } else {
                    videoSize = assetTrack.naturalSize
                }
                
                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = videoSize
                videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
                
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
                videoComposition.instructions = [instruction]
                let layerInstruction = self.compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
                instruction.layerInstructions = [layerInstruction]
                
                guard let export = AVAssetExportSession(asset: composition,
                                                        presetName: AVAssetExportPresetMediumQuality) else {
                    cdPrint("Cannot create export session.")
                    subscriber.onError(MsgError(code: -1, msg: "Cannot create export session."))
                    return
                }
                
                let videoName = UUID().uuidString
                let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mp4")
                self.exportedVideoURLs.append(exportURL)
                
                export.videoComposition = videoComposition
                export.outputFileType = .mp4
                export.outputURL = exportURL
                
                export.exportAsynchronously {
                    switch export.status {
                    case .completed:
                        subscriber.onNext(exportURL)
                        subscriber.onCompleted()
                    default:
                        cdPrint("Something went wrong during export.")
                        cdPrint(export.error ?? "unknown error")
                        subscriber.onError(export.error ?? MsgError(code: -1, msg: "unknown error"))
                        break
                    }
                }
                
                exportSession = export
            }
            
            return Disposables.create {
                exportSession?.cancelExport()
            }
        }
        .observeOn(MainScheduler.asyncInstance)
        
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    func clearExportedVideoFiles() {
        
        let urls = exportedVideoURLs
        
        DispatchQueue.global().async {
            urls.forEach { (url) in
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    cdPrint("\(Self.self) -> Can't remove the file for some reason.")
                }
            }
        }
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
                options.resizeMode = .none
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
