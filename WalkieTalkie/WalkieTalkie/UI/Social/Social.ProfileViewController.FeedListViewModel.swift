//
//  Social.ProfileViewController.FeedListViewModel.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/1.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Social.ProfileViewController {
    
    class FeedListViewModel {
        
        private let bag = DisposeBag()
        private let feedsRelay = BehaviorRelay<[Entity.Feed]>(value: [])
        private(set) var hasMore: Bool = true
        private let userId: Int
        private var isLoading = false
        
        var feedsObservable: Observable<[Entity.Feed]> {
            return feedsRelay.asObservable().observeOn(MainScheduler.asyncInstance)
        }
        
        var feeds: [Entity.Feed] {
            return feedsRelay.value
        }
        
        init(with uid: Int) {
            userId = uid
        }
        
        func loadFeeds() {
            
            guard hasMore,
                  !isLoading else {
                return
            }
            
            isLoading = true
            
            let skipMs = feedsRelay.value.last?.createTime ?? 0
            
            return Request.userFeeds(userId, skipMs: skipMs)
                .do(onDispose: { [weak self] in
                    self?.isLoading = false
                })
                .subscribe(onSuccess: { [weak self] (feedList) in
                    guard let `self` = self else { return }
                    
                    var cached = self.feedsRelay.value
                    cached.append(contentsOf: feedList.list)
                    self.feedsRelay.accept(cached)
                    self.hasMore = feedList.more
                    
                })
                .disposed(by: bag)
        }
        
    }
    
}
