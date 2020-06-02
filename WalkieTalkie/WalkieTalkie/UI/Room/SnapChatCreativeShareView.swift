//
//  SnapChatCreativeShareView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/5/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class SnapChatCreativeShareView: XibLoadableView {
    
    @IBOutlet weak var channelNameLabel: UILabel!
    
    init(with channel: String?) {
        super.init(frame: CGRect(x: 0, y: 0, width: 243, height: 180))
        channelNameLabel.text = channel?.showName ?? "WELCOME"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
