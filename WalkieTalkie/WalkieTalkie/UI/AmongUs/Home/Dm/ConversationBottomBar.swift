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
        case send(String)
//        case voice
    }

    @IBOutlet private weak var leftButton: UIButton!
    @IBOutlet private weak var gifButton: UIButton!
    @IBOutlet private weak var textField: PaddingTextField!
    @IBOutlet weak var voiceButton: HoldToTalkButton!

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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        textField.attributedPlaceholder = NSAttributedString(string: R.string.localizable.dmTextPlaceholder(), attributes: [NSAttributedString.Key.foregroundColor : "#646464".color()])
        textField.paddingLeft = 12
        textField.paddingRight = 12
    }

    @IBAction func leftButtonAction(_ sender: Any) {
        switch style {
        case .keyboard:
            style = .voice
        case .voice:
            style = .keyboard
        }
    }
    
    @IBAction func gifButtonAction(_ sender: Any) {
        actionHandler?(.gif)
    }
    
    @IBAction func voiceButtonAction(_ sender: Any) {
        cdPrint("voiceButtonAction")
    }
}


extension ConversationBottomBar: UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = true
//        isHidden = true
//        fadeOut(duration: 0.25, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = false
//        isHidden = false
//        alpha = 1
//        fadeIn(duration: 0.25, completion: nil)
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
//        textField.textColor = .white
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 200
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
//        textField.resignFirstResponder()
        
        guard let text = textField.text?.trim(),
              text.count > 0 else {
            return true
        }
        //send
        actionHandler?(.send(text))
        textField.clear()
        return true
    }
}

//extension AmongInputNickNameView {
//
//    func redAttributesString(text: String, redText: String) -> NSAttributedString {
//        let attributes = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16)])
//        if let range = text.nsRange(of: redText) {
//            attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], range: range)
//        }
//        return attributes
//    }
//
//    func updateSelectedButton() {
//
//    }
//}

