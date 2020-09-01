//
//  Social.UserList.ViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift

extension Social.UserList {
    
    class UserViewModel {
        
        private let user: FireStore.Entity.User
        
        init(with data: FireStore.Entity.User) {
            user = data
        }
        
        var username: String {
            return user.profile.name
        }
        
        var channel: String {
            return user.status.currentChannel
        }
        
        var online: Bool {
            return user.status.online
        }
        
        var isFriend: Bool {
            let inFollowing = { (userId: String) in
                return Social.Module.shared.followingValue().map{ $0.uid }.contains(userId)
            }
            let inFollower = { (userId: String) in
                return Social.Module.shared.followerValue().map { $0.uid }.contains(userId)
            }
            return inFollowing(user.uid) && inFollower(user.uid)
        }
        
        var avatar: Single<UIImage?> {
            return Observable<UIImage?>.create { (subscriber) -> Disposable in
                
                // TODO: avatar fetching
                
                
                return Disposables.create {
                    
                }
            }
            .asSingle()
        }
        
        var status: String {
            
            let statusString: String
            
            if user.status.online {
                
                if user.status.currentChannel.isEmpty {
                    statusString = "Online"
                } else if user.status.currentChannel.starts(with: "_"){
                    statusString = "In Secret Room"
                } else {
                    statusString = "In \(user.status.currentChannel)"
                }
                
            } else {
                statusString = "Offline"
            }
            
            return statusString
        }
        
    }
    
}
