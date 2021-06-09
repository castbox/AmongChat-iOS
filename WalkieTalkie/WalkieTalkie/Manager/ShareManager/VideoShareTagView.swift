//
//  VideoShareTagView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 31/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class VideoShareTagView: XibLoadableView {

    @IBOutlet weak var nameLabel: UILabel!
    
    init(with name: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: Frame.Screen.width - 40, height: 64))
        self.nameLabel.text = "@\(name)"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
