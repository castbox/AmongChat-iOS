//
//  FansGroup.Notifications.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/14.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension FansGroup {
    
    struct GroupUpdateNotification {
        
        static let notificationName = Notification.Name("among.chat.fans.group.update")
        static let actionKey = "action"
        static let groupEntityKey = "group"
        
        enum Action {
            case added
            case removed
            case updated
        }
        
        static func getDataFromNotification(_ notification: Notification) -> (Action, Entity.Group)? {
            
            guard let userInfo = notification.userInfo,
                  let action = userInfo[actionKey] as? Action,
                  let group = userInfo[groupEntityKey] as? Entity.Group else {
                return nil
            }
            
            return (action, group)
        }
        
        static func publishNotificationOf(group: Entity.Group, action: Action) {
            NotificationCenter.default.post(name: FansGroup.GroupUpdateNotification.notificationName,
                                            object: nil, userInfo: [
                                                FansGroup.GroupUpdateNotification.actionKey : action,
                                                FansGroup.GroupUpdateNotification.groupEntityKey : group
                                            ])
        }
        
    }
    
}
