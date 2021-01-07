//
//  SocialTiktokItemView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 05/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class SocialTiktokItemView: XibLoadableView {
    @IBOutlet weak var button: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        button.setBackgroundImage("#222222".color().image, for: .normal)
    }
    
    @IBAction func onClick(_ sender: Any) {
        Logger.Action.log(.profile_tiktok_amongchat_tag_clk)
        guard let url = URL(string: "https://www.tiktok.com/tag/amongchat") else {
            return
        }
        UIApplication.shared.open(url, options: [:]) { _ in
            
        }
    }
}
