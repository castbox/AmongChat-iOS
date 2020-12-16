//
//  AmongInputCodeView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongInputCodeView: XibLoadableView {

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var inputContainerView: UIView!
        
    @IBOutlet weak var northAmericaButton: UIButton!
    @IBOutlet weak var asiaButton: UIButton!
    @IBOutlet weak var europeButton: UIButton!
    
    private var locationService: AmongChat.AmongServiceLocation = .northAmerica
    
    var inputResultHandler: ((String, AmongChat.AmongServiceLocation) -> Void)?

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
//    func show() {
//        textField.becomeFirstResponder()
//    }
//
//    func hide() {
//
//    }

    @IBAction func serviceLocationAction(_ sender: UIButton) {
        guard let location = AmongChat.AmongServiceLocation(rawValue: sender.tag) else {
            return
        }
        locationService = location
        northAmericaButton.setBackgroundImage("D8D8D8".color().image, for: .normal)
        asiaButton.setBackgroundImage("D8D8D8".color().image, for: .normal)
        europeButton.setBackgroundImage("D8D8D8".color().image, for: .normal)
        
        switch location {
        case .northAmerica:
            northAmericaButton.setBackgroundImage("FFF000".color().image, for: .normal)
        case .asia:
            asiaButton.setBackgroundImage("FFF000".color().image, for: .normal)
        case .europe:
            europeButton.setBackgroundImage("FFF000".color().image, for: .normal)
        }
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        _ = textField.resignFirstResponder()

    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        _ = textField.resignFirstResponder()
        guard let code = textField.text else {
            return
        }
        inputResultHandler?(code, locationService)
    }
    
}

extension AmongInputCodeView: UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = true
//        isHidden = true
        alpha = 0
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = false
//        isHidden = false
        alpha = 1
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
//        imViewModel.sendMessage(text)
        return true
    }
}

extension AmongInputCodeView {
    func updateSelectedButton() {
        
    }
}
