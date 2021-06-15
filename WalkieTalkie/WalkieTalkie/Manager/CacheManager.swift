//
//  CacheManager.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/15.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift

class CacheManager {
    
    private lazy var cacheDirs: [String] = [
        FileManager.CachesDirectory(),
        FileManager.TmpDirectory(),
        SZAVPlayerFileSystem.cacheDirectory.absoluteString
    ]
    
    func cacheFormatedSize() -> Single<String> {
        
        return Single<String>.create { [weak self] (subscriber) -> Disposable in
            
            let totalSize = self?.cacheDirs.map {
                FileManager.fileOrDirectorySize(path: $0)
            }
            .reduce(0, +) ?? 0
            
            let formatedSize = FileManager.covertUInt64ToString(with: totalSize)
            
            subscriber(.success(formatedSize))
            
            return Disposables.create {
                
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: DispatchQueue.global()))
        .observeOn(MainScheduler.asyncInstance)
        
    }
    
    func clearCache() -> Single<Void> {
        
        return Single<Void>.create { [weak self] (subscriber) -> Disposable in
            
            self?.cacheDirs.forEach({
                FileManager.removefolder(folderPath: $0)
            })
            
            subscriber(.success(()))
            
            return Disposables.create {
                
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler.init(queue: DispatchQueue.global()))
        .observeOn(MainScheduler.asyncInstance)
        
    }
    
    
}
