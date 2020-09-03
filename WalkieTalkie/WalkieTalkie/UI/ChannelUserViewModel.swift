//
//  ChannelUserViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift

class ChannelUserViewModel {
    
    let channelUser: ChannelUser
    let firestoreUser: FireStore.Entity.User?
    
    init(with channelUser: ChannelUser, firestoreUser: FireStore.Entity.User?) {
        self.channelUser = channelUser
        self.firestoreUser = firestoreUser
    }
    
    var name: String {
        if let profile = firestoreUser?.profile {
            return profile.name
        } else {
            return channelUser.name
        }
    }
    
    var avatar: Single<UIImage?> {
        return Observable<UIImage?>.create { [weak self] (subscriber) -> Disposable in
            
            // TODO: avatar fetching
            
            if let profile = self?.firestoreUser?.profile {
                let _ = profile.avatarObservable.subscribe(onSuccess: { (image) in
                    subscriber.onNext(image)
                    subscriber.onCompleted()
                })
                
            } else {
                subscriber.onNext(nil)
                subscriber.onCompleted()
            }
            
            return Disposables.create {
                
            }
        }
        .asSingle()
    }
}
