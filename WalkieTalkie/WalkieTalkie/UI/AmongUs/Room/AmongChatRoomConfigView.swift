//
//  AmongChatRoomConfigView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit

class AmongChatRoomConfigView: XibLoadableView {

    let topic: AmongChat.Topic
    let topicDetail: Bool
    //view
    lazy var amongSetupView = AmongRoomInfoSetupView()
    lazy var amongInfoView = AmongRoomInfoView()
    
    lazy var justChillingInfoView = JustChillingInfoView()
    
    
    init(_ topic: AmongChat.Topic, topicDetail: Bool) {
        self.topic = topic
        self.topicDetail = topicDetail
        super.init(frame: .zero)
        configureSubview()
        bindSubviewEvent()
        updateSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AmongChatRoomConfigView {
    
    func updateSubview() {
        switch topic {
        case .amongus:
            //
            justChillingInfoView.isHidden = true
            amongSetupView.isHidden = topicDetail
            amongInfoView.isHidden = !topicDetail
            if topicDetail {
              //已配置
                
            } else {
                //未配置
            }
        case .chilling:
            justChillingInfoView.isHidden = false
            amongSetupView.isHidden = true
            amongInfoView.isHidden = true
            
        }
    }
    
    func bindSubviewEvent() {
        amongSetupView.setupButtonClick = { [weak self] in
            
        }
    }
    
    func configureSubview() {
        amongSetupView.isHidden = true
        amongInfoView.isHidden = true
        justChillingInfoView.isHidden = true
        addSubviews(views: amongSetupView, amongInfoView, justChillingInfoView)
        
        amongSetupView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        amongInfoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        justChillingInfoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

    }
}
