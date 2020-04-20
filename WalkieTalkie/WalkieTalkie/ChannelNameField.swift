//
//  ChannelNameField.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class ChannelNameField: UITextField {
    var didBeginEditing: ((UITextField) -> Void)?
    var didReturn: ((UITextField) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = self
    }

}

extension ChannelNameField: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?(textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let length = textField.text?.count ?? 0
        let result = length >= 2 && length <= 8
        if result {
            _ = textField.resignFirstResponder()
            didReturn?(textField)
        }
        return result
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let set = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-").inverted
        let filteredString = string.components(separatedBy: set).joined(separator: "")
        let checkLength = checkTextLength(textField, shouldChangeCharactersIn: range, replacementString: string)
        if filteredString == string && checkLength {
            return true
        }else {
            return false
        }
    }
    
    func checkTextLength(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let limitation = 8
        let currentLength = textField.text?.count ?? 0 // 当前长度
        if (range.length + range.location > currentLength){
            return false
        }
        // 禁用启用按钮
        let newLength = currentLength + string.count - range.length // 加上输入的字符之后的长度
        return newLength <= limitation
    }
}
