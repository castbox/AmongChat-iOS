//
//  TikTokShareView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/7/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class TikTokShareView: XibLoadableView {
    
    enum Content {
        case public_1
        case public_2
        case private_1
        case private_2
    }

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var shareContentLabel: UILabel!
    @IBOutlet weak var shareContentleftConstraint: NSLayoutConstraint!
    
    let content: Content
    let channelName: String
    
    init(_ channelName: String, content: Content) {
        self.content = content
        self.channelName = channelName
        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        backgroundImageView.image = content.backgroundImage
//        channelNameLabel.text = channelName.showName
//        shareContentLabel.text = content.contentTitle(channelName.showName)
        shareContentleftConstraint.constant = content.titleleftEdge
//        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TikTokShareView.Content {
    var titleleftEdge: CGFloat {
        switch self {
        case .public_1, .private_1:
            return 108
        case .public_2, .private_2:
            return 57
        }
    }
        
    var backgroundImage: UIImage? {
        return nil
//        switch self {
//        case .public_1:
//            return R.image.public_share_bg_2()
//        case .public_2:
//            return R.image.public_share_bg()
//        case .private_1:
//            return R.image.private_share_bg_2()
//        case .private_2:
//            return R.image.private_share_bg()
//        }
    }
//    "share.tiktok.public.title" = "Join in %@ talk to me & have fun !!!";
//    "share.tiktok.private.title" = "Join in my SERET CHANNEL %@ talk to me !!!";
//    "share.tiktok.content.dowload" = "Download “walkie talkie talk to friends” First";
    func contentTitle(_ channelName: String) -> String {
//        switch self {
//        case .public_1:
//            return R.string.localizable.shareTiktokPublicTitle(channelName)
//        case .private_1:
//            return R.string.localizable.shareTiktokPrivateTitle(channelName)
//        case .public_2, .private_2:
//            return R.string.localizable.shareTiktokContentDowload()
//        }
        return ""
    }
}
