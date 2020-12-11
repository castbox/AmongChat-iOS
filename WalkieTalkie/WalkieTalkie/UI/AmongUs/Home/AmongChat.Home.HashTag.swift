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
        
        let channelCategory: FireStore.ChannelCategory
        let didSelect: (() -> Void)
        
        var icon: UIImage? {
            switch channelCategory.type {
            case .amongUs:
                return R.image.launch_logo()
            case .createSecret:
                return R.image.icon_pri_ad()
            default:
                return nil
            }
        }
        
        var name: String {
            return channelCategory.name
        }
        
    }
    
}
