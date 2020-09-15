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
        
        let user: FireStore.Entity.User
        
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
            guard let selfUid = Settings.shared.loginResult.value?.uid,
                !user.blockList.contains(selfUid) else {
                return false
            }
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
            
            if online {
                
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
        
        func follow() {
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
            FireStore.shared.addFollowing(userId, to: selfUid)
        }
        
        var joinable: Bool {
            guard let selfUid = Settings.shared.loginResult.value?.uid,
                !user.blockList.contains(selfUid) else {
                return false
            }
            
            guard !Social.Module.shared.blockedValue.contains(user.profile.uid) else {
                return false
            }
            
            return !channelName.isEmpty
        }
        
        func joinUserRoom() {
            guard let profile = Settings.shared.firestoreUserProfile.value else { return }
            if channelIsSecrete {
                FireStore.shared.sendJoinChannelRequest(from: profile, to: userId, toJoin: channelId)
            } else if let roomVC = UIApplication.navigationController?.viewControllers.first as? RoomViewController {
                // join channel directly
                roomVC.joinChannel(channelId)
                UIApplication.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        var invitable: Bool {
            guard let selfUid = Settings.shared.loginResult.value?.uid,
                !user.blockList.contains(selfUid) else {
                return false
            }

            guard !Social.Module.shared.blockedValue.contains(user.profile.uid) else {
                return false
            }
            
            guard isFriend else {
                return false
            }
            
            let iHaveARoom = !Social.Module.shared.currentChannelValue.isEmpty
            let heIsOnline = user.status.online
            
            return iHaveARoom || !heIsOnline
        }
        
        func invite() {
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
            FireStore.shared.sendChannelInvitation(to: userId, toJoin: Social.Module.shared.currentChannelValue, from: selfUid)
        }
        
    }
    
}
