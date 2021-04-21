//
//  AmongChat.Room.MessageInputView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Room {
    class MessageInputView: UIView {
        private let sendable: SendMessageable
        private lazy var messageInputField: UITextField = {
            let f = UITextField(frame: CGRect.zero)
            f.backgroundColor = UIColor("#151515")
            f.borderStyle = .none
            let leftMargin = UIView()
            leftMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            let rightMargin = UIView()
            rightMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            f.keyboardAppearance = .dark
            f.leftView = leftMargin
            f.rightView = rightMargin
            f.leftViewMode = .always
            f.rightViewMode = .always
            f.returnKeyType = .send
            f.attributedPlaceholder = NSAttributedString(string: R.string.localizable.amongChatRoomMessagePlaceholder(),
                                                         attributes: [
                                                            NSAttributedString.Key.foregroundColor : UIColor("#8A8A8A")
                                                         ])
            f.textColor = .white
            f.delegate = self
            f.font = R.font.nunitoSemiBold(size: 13)
            return f
        }()
        
        init(sendable: SendMessageable) {
            self.sendable = sendable
            super.init(frame: .zero)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func becomeFirstResponder() -> Bool {
            return messageInputField.becomeFirstResponder()
        }
        
        private func bindSubviewEvent() {
            
        }
        
        private func configureSubview() {
            addSubview(messageInputField)
            messageInputField.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.height.equalTo(50)
            }
            
        }
    }
}

extension AmongChat.Room.MessageInputView: UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        isHidden = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        superview?.bringSubviewToFront(self)
        isHidden = false
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
        //text
        sendable.sendText(message: text)
        return true
    }
}
