//
//  MessageCellViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Conversation {
    class MessageCellViewModel {
        let message: Entity.DMMessage
        let height: CGFloat
        let showTime: Bool
        let contentSize: CGSize
        let sendFromMe: Bool
        let dateString: String
        //
        var isPlayingVoice: Bool = false
        var ms: Double {
            message.ms ?? 0
        }
        
        init(message: Entity.DMMessage, showTime: Bool) {
            self.message = message
            self.showTime = showTime
            self.sendFromMe = message.fromUser.uid == Settings.loginUserId?.int64
            dateString = message.date.timeFormattedForConversation()
            //calculate height
            let maxWidth = Frame.Screen.width - 72 * 2
            
            switch message.body.msgType {
            case .text:
                let textSize = message.body.text?.boundingRect(with: CGSize(width: maxWidth, height: 1000), font: R.font.nunitoBold(size: 16)!) ?? CGSize(width: 0, height: 0)
                contentSize = textSize.ceil
                let topBottomEdge: CGFloat = 9 + 9.5 + 12
                var height = contentSize.height + topBottomEdge
                if showTime {
                    height += 31
                }
                self.height = height
            case .gif, .feed:
                //最小
                let minWidth: CGFloat = 80
                let gifMaxWidth: CGFloat = 170
                let rawHeight = (message.body.imageHeight?.cgFloat ?? 1)
                let rawWidth = (message.body.imageWidth?.cgFloat ?? 1)
                var gifWidth = rawWidth
                var gifHeight = rawHeight
                if gifWidth > gifMaxWidth {
                    gifWidth = gifMaxWidth
//                    gifHeight = gifMaxWidth * rawHeight / rawWidth
                } else if gifWidth < minWidth {
                    gifWidth = minWidth
//                    gifHeight = minWidth * rawHeight / rawWidth
                }
                gifHeight = gifWidth / 3 * 4
                contentSize = CGSize(width: gifWidth, height: gifHeight)
                
                let topEdge: CGFloat = 6
                var height = contentSize.height + topEdge * 2
                if showTime {
                    height += 31
                }
                self.height = height
            case .voice:
                //                let topEdge: CGFloat = 6
                contentSize = CGSize(width: max(100, Double(maxWidth) / 60 * (message.body.duration ?? 0)), height: 40)
                var height: CGFloat = 48
                if showTime {
                    height += 31
                }
                self.height = height
            case .none:
                let maxWidth = Frame.Screen.width - 72 * 2
                contentSize = CGSize(width: Double(maxWidth) / 60 * (message.body.duration ?? 0), height: 40)
                self.height = 0
            }
        }
    }
}
