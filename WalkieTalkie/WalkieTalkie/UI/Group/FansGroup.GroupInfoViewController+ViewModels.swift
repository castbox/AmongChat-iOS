//
//  FansGroup.GroupInfoViewController+ViewModels.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension FansGroup.GroupInfoViewController {
    
    class GroupViewModel {
        
        let groupInfo: Entity.GroupInfo
        
        init(groupInfo: Entity.GroupInfo) {
            self.groupInfo = groupInfo
        }
        
        var name: String? {
            return groupInfo.group.name
        }
        
        var description: String? {
            return groupInfo.group.description
        }
        
        var cover: String? {
            return groupInfo.group.cover
        }
        
        var userStatus: Entity.GroupInfo.UserStatus {
            
            guard let s = groupInfo.userStatusEnum else {
                return .none
            }

            return s
        }
    }
    
}

extension FansGroup.GroupInfoViewController {
    
    class MemberViewModel {
        
        let user: Entity.UserProfile
        
        init(user: Entity.UserProfile) {
            self.user = user
        }
    }
    
}
