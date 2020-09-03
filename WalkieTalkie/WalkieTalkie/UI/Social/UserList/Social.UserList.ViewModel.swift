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
        
        var userId: String {
            return user.uid
        }
        
        var username: String {
            return user.profile.name
        }
        
        var channelId: String {
            return user.status.currentChannel
        }
        
        var channelName: String {
            if user.status.currentChannel.starts(with: "_"){
                return "Secret Room"
            } else {
                return user.status.currentChannel
            }
        }
        
        var channelIsSecrete: Bool {
            if user.status.currentChannel.starts(with: "_"){
                return true
            } else {
                return false
            }
        }
        
        var online: Bool {
            return user.status.online
        }
        
        var isFriend: Bool {
            let inFollowing = { (userId: String) in
                return Social.Module.shared.followingValue.map{ $0.uid }.contains(userId)
            }
            let inFollower = { (userId: String) in
                return Social.Module.shared.followerValue.map { $0.uid }.contains(userId)
            }
            return inFollowing(user.uid) && inFollower(user.uid)
        }
        
        var avatar: Single<UIImage?> {
            return user.profile.avatarObservable
        }
        
        var status: String {
            
            let statusString: String
            
            if user.status.online {
                
                if channelName.isEmpty {
                    statusString = "Online"
                } else {
                    statusString = "In \(channelName)"
                }
                
            } else {
                statusString = "Offline"
            }
            
            return statusString
        }
        
    }
    
}
