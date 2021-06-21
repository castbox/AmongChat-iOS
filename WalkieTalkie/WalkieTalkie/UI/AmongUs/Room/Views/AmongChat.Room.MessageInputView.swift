//
//  AmongChat.Room.MessageInputView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension AmongChat.Room {
    class MessageInputView: UIView {
        private let sendable: SendMessageable

        private let bag = DisposeBag()
        
        private let maxInputLength = Int(256)
        private let textViewMinHeight = CGFloat(19)
        private let textViewMaxHeight = CGFloat(56)
        
        private lazy var blurView: UIVisualEffectView = {
            let b = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            return b
        }()
                
        private lazy var inputTextView: UITextView = {
            let f = UITextView()
            f.backgroundColor = .clear
            f.keyboardAppearance = .dark
            f.returnKeyType = .send
            f.textContainerInset = .zero
            f.textContainer.lineFragmentPadding = 0
            f.delegate = self
            f.font = R.font.nunitoExtraBold(size: 14)
            f.textColor = .white
            f.rx.text
                .subscribe(onNext: { [weak self] (text) in
                    
                    guard let `self` = self else { return }
                    
                    self.placeholderLabel.isHidden = (text != nil) && text!.count > 0
                    
                })
                .disposed(by: bag)
            f.showsVerticalScrollIndicator = false
            f.showsHorizontalScrollIndicator = false
            return f
        }()
        
        private lazy var placeholderLabel: UILabel = {
            let l = UILabel()
            l.numberOfLines = 0
            l.text = R.string.localizable.amongChatRoomMessagePlaceholder()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = UIColor(hex6: 0xFFFFFF, alpha: 0.3)
            return l
        }()
        
        init(sendable: SendMessageable) {
            self.sendable = sendable
            super.init(frame: .zero)
            configureSubview()
            bindSubviewEvent()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func becomeFirstResponder() -> Bool {
            return inputTextView.becomeFirstResponder()
        }
        
        private func bindSubviewEvent() {
            inputTextView.rx.text
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    
                    let contentHeight = self.inputTextView.contentSize.height
                    let height = min(self.textViewMaxHeight, max(self.textViewMinHeight, contentHeight))
                    self.inputTextView.snp.updateConstraints { (maker) in
                        maker.height.equalTo(height)
                    }
                
                    if contentHeight <= self.textViewMaxHeight {
                        self.inputTextView.setContentOffset(.zero, animated: false)
                    }
                })
                .disposed(by: bag)
        }
        
        private func configureSubview() {
            addSubviews(views: blurView, inputTextView, placeholderLabel)
            
            blurView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            inputTextView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))
                maker.height.equalTo(textViewMinHeight)
            }
            
            placeholderLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(inputTextView)
                maker.leading.equalToSuperview().offset(23)
            }

        }
    }
}

extension AmongChat.Room.MessageInputView: UITextViewDelegate {
    
    // MARK: - UITextView Delegate
    
    func textViewDidEndEditing(_ textView: UITextView) {
        isHidden = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        superview?.bringSubviewToFront(self)
        isHidden = false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textFieldText = textView.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
        
        if text == "\n"{
            // do your stuff here
            // return false here, if you want to disable user from adding newline
            textView.resignFirstResponder()

            guard let text = textView.text,
                  text.count > 0 else {
                return false
            }
            
            textView.clear()
            //text
            sendable.sendText(message: text)
            
            return false
        }
        
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + text.count
        return count <= maxInputLength
    }
    
}
