//
//  ConversationBottomBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 10/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ConversationBottomBar: XibLoadableView {
    enum Style {
        case voice
        case keyboard
    }
    
    enum Action {
        case gif
    }

    @IBOutlet private weak var leftButton: UIButton!
    @IBOutlet private weak var gifButton: UIButton!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var voiceButton: UIButton!
    
    private var style: Style = .keyboard {
        didSet {
            switch style {
            case .keyboard:
                leftButton.setImage(R.image.iconDmVoice(), for: .normal)
                textField.isHidden = false
            case .voice:
                leftButton.setImage(R.image.iconDmKeyboard(), for: .normal)
                textField.isHidden = true
            }
            voiceButton.isHidden = !textField.isHidden
        }
    }
    
    var actionHandler: ((Action) -> Void)?

    @IBAction func leftButtonAction(_ sender: Any) {
        switch style {
        case .keyboard:
            style = .voice
        case .voice:
            style = .keyboard
        }
    }
    
    @IBAction func gifButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func voiceButtonAction(_ sender: Any) {
        
    }
}

extension ConversationBottomBar: UITextFieldDelegate {
    
}
