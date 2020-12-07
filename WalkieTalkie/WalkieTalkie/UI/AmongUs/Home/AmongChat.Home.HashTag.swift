//
//  AmongChat.Home.HashTagsViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/26.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    struct HashTag {
        
        enum TagType {
            case amongUs
            case groupChat
            case createPrivate
            case joinPrivate
        }
        
        let type: TagType
        let didSelect: (() -> Void)
        
        var icon: UIImage? {
            switch type {
            case .amongUs:
                return R.image.launch_logo()
            case .createPrivate:
                return R.image.icon_pri_ad()
            default:
                return nil
            }
        }
        
        var name: String {
            switch type {
            case .amongUs:
                return R.string.localizable.amongChatHomeTagAmong()
            case .groupChat:
                return R.string.localizable.amongChatHomeTagGroup()
            case .createPrivate:
                return R.string.localizable.amongChatHomeTagCreatePrivate()
            case .joinPrivate:
                return R.string.localizable.amongChatHomeTagJoinPrivate()
            }
        }
        
    }
    
}
