//
//  AmongChat.Home.TopicViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import Kingfisher

extension AmongChat.Home {
    
    class TopicViewModel {
        
        private static var imageCache: [String : UIImage] = [:]
        
        let topic: Entity.SummaryTopic
        
        init(with topic: Entity.SummaryTopic) {
            self.topic = topic
        }
        
        var name: String {
            return topic.topicName ?? ""
        }
        
        var coverObvervable: Single<UIImage> {
            return fetchImage(of: topic.coverUrl)
        }
        
        var bgObservable: Single<UIImage> {
            return fetchImage(of: topic.bgUrl)
        }
        
        var nowPlaying: String {
            return R.string.localizable.amongChatHomeNowplaying("\(topic.playerCount ?? 0)")
        }
        
        private func fetchImage(of urlStr: String?) -> Single<UIImage> {
            
            guard let urlStr = urlStr,
                let url = URL(string: urlStr) else {
                return Single.error(NSError(domain: NSStringFromClass(Self.self), code: 404, userInfo: nil))
            }
            
            let ob = KingfisherManager.shared.retrieveImageObservable(with: url)
                .do(onNext: { (image) in
                    Self.imageCache[urlStr] = image
                })
                .asSingle()

            guard let image = Self.imageCache[urlStr] else {
                return ob
            }
            
            let _ = ob.subscribe(onSuccess: { _ in })
            
            return Single.just(image)
            
        }
        
    }
    
}
