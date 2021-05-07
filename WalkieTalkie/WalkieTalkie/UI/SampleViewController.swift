//
//  SampleViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class SampleViewController: WalkieTalkie.ViewController {
    
    override var isHidesBottomBarWhenPushed: Bool {
        return false
    }
    
    private lazy var navigationView = AmongChat.Home.NavigationBar(.notice)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubviews(views: navigationView)
        
        navigationView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }

    }
    
}
