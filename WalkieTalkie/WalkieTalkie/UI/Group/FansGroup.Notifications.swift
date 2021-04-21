//
//  FansGroup.Notifications.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/14.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension FansGroup {
    
    struct GroupUpdateNotification {
        
        private static let notificationName = Notification.Name("among.chat.fans.group.update")
        private static let actionKey = "action"
        private static let groupEntityKey = "group"
        
        enum Action {
            case added
            case removed
            case updated
        }
                        
        static var groupUpdated: Observable<(Action, Entity.Group)> {
            return NotificationCenter.default.rx.notification(notificationName)
                .map { (notification) -> (Action, Entity.Group)? in
                    guard let userInfo = notification.userInfo,
                          let action = userInfo[actionKey] as? Action,
                          let group = userInfo[groupEntityKey] as? Entity.Group else {
                        return nil
                    }
                    
                    return (action, group)
                }
                .filterNil()
        }
        
        static func publishNotificationOf(group: Entity.Group, action: Action) {
            NotificationCenter.default.post(name: notificationName,
                                            object: nil, userInfo: [
                                                actionKey : action,
                                                groupEntityKey : group
                                            ])
        }
        
    }
    
}
