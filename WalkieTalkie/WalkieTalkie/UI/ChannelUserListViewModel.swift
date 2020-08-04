//
//  ChannelUserListViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/8/4.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyUserDefaults

class ChannelUserListViewModel {
    static let shared = ChannelUserListViewModel()
    
    var dataSourceReplay = BehaviorRelay<[ChannelUser]>(value: [])
    
    private var dataSource = [ChannelUser]() {
        didSet {
            dataSourceReplay.accept(dataSource)
        }
    }
    
    var blockedUsers = [ChannelUser]()
    
    init() {
        blockedUsers = Defaults[\.blockedUsersKey]
    }
    
    func update(_ userList: [ChannelUser]) {
        let blockedUsers = self.blockedUsers
        dataSource = userList.map { item -> ChannelUser in
            var user = item
            if blockedUsers.contains(where: { $0.uid == item.uid }) {
                user.isMuted = true
                user.status = .blocked
            } else {
                user.isMuted = false
                user.status = .connected
            }
            return user
        }
    }
    
    func updateVolumeIndication(userId: String, volume: UInt) {
        dataSource = dataSource.map { item -> ChannelUser in
            guard item.status != .blocked, item.uid == userId else {
                return item
            }
            var user = item
            user.status = .talking
            return user
        }
    }
    
    func blockedUser(_ user: ChannelUser) {
        blockedUsers.append(user)
        Defaults[\.blockedUsersKey] = blockedUsers
        update(dataSource)
    }
    
    func unblockedUser(_ user: ChannelUser) {
        blockedUsers.removeElement(ifExists: { $0.uid == user.uid })
        Defaults[\.blockedUsersKey] = blockedUsers
        update(dataSource)
    }
}
