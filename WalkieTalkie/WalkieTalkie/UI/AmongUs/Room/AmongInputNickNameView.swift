//
//  AmongInputNickNameView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SwifterSwift

class AmongInputNickNameView: XibLoadableView {
    
    @IBOutlet weak var textField: PaddingTextField!
    
    @IBOutlet weak var inputContainerView: UIView!
    
    var inputResultHandler: ((String) -> Void)?
    var usedInRoom = true
    
    func becomeFirstResponder(with room: Entity.Room? = nil) -> Bool {

        if usedInRoom {
            switch room?.topicType {
            case .roblox:
                textField.placeholder = R.string.localizable.roomRobloxInputCodePlceholder()
                textField.text = Settings.shared.amongChatUserProfile.value?.nameRoblox
            case .fortnite:
                textField.placeholder = R.string.localizable.roomFortniteInputCodePlceholder()
                textField.text = Settings.shared.amongChatUserProfile.value?.nameFortnite
            case .freefire:
                textField.placeholder = R.string.localizable.roomFreefireInputCodePlceholder()
                textField.text = Settings.shared.amongChatUserProfile.value?.nameFreefire
//            case .freefire:
//                textField.placeholder = R.string.localizable.roomFreefireInputCodePlceholder()
//                textField.text = Settings.shared.amongChatUserProfile.value?.nameFreefire
            default:
                ()
            }
        } else {
            textField.placeholder = R.string.localizable.profileBagNickname()
            textField.text =  Settings.shared.amongChatUserProfile.value?.name
        }
        return textField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    @IBAction func cancelButtonAction(_ sender: Any) {
        _ = textField.resignFirstResponder()

    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        guard let name = textField.text?.trimmed else {
            return
        }
        if let text = SensitiveWordChecker.firstSensitiveWord(in: name) {
            //show
            textField?.attributedText = redAttributesString(text: name, redText: text)
            raft.autoShow(.text(R.string.localizable.contentContainSensitiveWords()))
            return
        }
        _ = textField.resignFirstResponder()
        inputResultHandler?(name)
    }
    
}

extension AmongInputNickNameView: UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = true
//        isHidden = true
        fadeOut(duration: 0.25, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = false
//        isHidden = false
//        alpha = 1
        fadeIn(duration: 0.25, completion: nil)
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 30
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        guard let text = textField.text,
              text.count > 0 else {
            return true
        }
        
        textField.clear()
        return true
    }
}

extension AmongInputNickNameView {
    
    func redAttributesString(text: String, redText: String) -> NSAttributedString {
        let attributes = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16)])
        if let range = text.nsRange(of: redText) {
            attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], range: range)
        }
        return attributes
    }
    
    func updateSelectedButton() {
        
    }
}
