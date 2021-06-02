//
//  Feed.ListCellViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 02/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import UIKit

extension Feed {
    class ListCellViewModel { //: Equatable
        
        var feed: Entity.Feed {
            didSet {
                updateEmotes()
            }
        }
        
        var emotes: [Entity.FeedEmote] = []
        
        init(feed: Entity.Feed) {
            self.feed = feed
            updateEmotes()
        }
        
        func updateEmoteState(emoteId: String, isSelect: Bool) {
            if isSelect {
                //当前列表有
                if let emote = feed.emotes.first(where: { $0.id == emoteId }) {
                    emote.count += 1
                    emote.isVoted = true
                } else {
                    //无，则添加
                    feed.emotes.append(Entity.FeedEmote(id: emoteId, count: 1, isVoted: true))
                }
            } else {
                //unselected
                if let emote = feed.emotes.first(where: { $0.id == emoteId }) {
                    emote.count -= 1
                    emote.isVoted = false
                    feed.emotes = feed.emotes.filter { $0.count > 0 }
                }
            }
            updateEmotes()
        }
        
        func increasementCommentCount() {
            feed.cmtCount += 1
        }
        
        private func updateEmotes() {
            let feedEmotes = Settings.shared.globalSetting.value?.feedEmotes ?? []
            
            var emotes = feed.emotes.map { item -> Entity.FeedEmote in
                let emote = item
                //calculate width
                let countWidth = item.count.string.boundingRect(with: CGSize(width: 100, height: 20), font: R.font.nunitoExtraBold(size: 14)!).width
                emote.width = countWidth + 60
                guard let feedEmote = feedEmotes.first(where: { $0.id == item.id }) else {
                    return emote
                }
                emote.url = feedEmote.resource
                emote.img = feedEmote.img
                return emote
            }.sorted { $0.count > $1.count }
            
            emotes.insert(Entity.FeedEmote(id: "", count: 0, isVoted: false, width: 60), at: 0)
            
            self.emotes = emotes
        }
    }
}
