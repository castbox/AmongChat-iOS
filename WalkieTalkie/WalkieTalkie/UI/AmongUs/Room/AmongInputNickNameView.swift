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

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var inputContainerView: UIView!
    
    var inputResultHandler: ((String) -> Void)?
    
    override func becomeFirstResponder() -> Bool {
        textField.text = Settings.shared.amongChatUserProfile.value?.nickname
        return textField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    @IBAction func cancelButtonAction(_ sender: Any) {
        _ = textField.resignFirstResponder()

    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        _ = textField.resignFirstResponder()
        guard let name = textField.text?.trimmed else {
            return
        }
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
        return count <= 256
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
    func updateSelectedButton() {
        
    }
}
