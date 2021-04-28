//
//  Notice.NoticeViewModel.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/28.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Notice {
    
    class NoticeViewModel {
        
        private(set) var notice: Entity.Notice
        private(set) var itemsSize: CGSize
        private(set) var timeString: String
        
        init(with notice: Entity.Notice) {
            self.notice = notice
            
            switch notice.message.messageType {
            case .TxtMsg, .ImgMsg, .ImgTxtMsg, .TxtImgMsg:
                itemsSize = Notice.Views.SystemMessageCell.cellSize(for: notice)
            case .SocialMsg:
                itemsSize = Notice.Views.SocialMessageCell.cellSize(for: notice)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
            dateFormatter.locale = Locale.current
            let date = Date(timeIntervalSince1970: Double(notice.ms) / 1000.0)
            timeString = dateFormatter.string(from: date)
        }
        
        func action() {
            
            guard let link = notice.message.link else {
                return
            }
            
            Routes.handle(link)

        }
        
    }
    
}
