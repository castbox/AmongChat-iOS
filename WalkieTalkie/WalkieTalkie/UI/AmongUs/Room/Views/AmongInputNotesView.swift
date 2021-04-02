//
//  AmongInputNotesView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongInputNotesView: XibLoadableView {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var hostNotesPlaceholderLabel: UILabel!
    
    var inputResultHandler: ((String) -> Void)?
    var notes: String? {
        didSet {
            textView.text = notes
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 20)
    }
    
    func show(with room: RoomInfoable) {
        hostNotesPlaceholderLabel.isHidden = room.note.isValid
        textView.text = room.note
        _ = becomeFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }

    @IBAction func cancelButtonAction(_ sender: Any) {
        _ = textView.resignFirstResponder()

    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        guard let name = textView.text else {
            _ = textView.resignFirstResponder()
            return
        }
        if let text = SensitiveWordChecker.firstSensitiveWord(in: name) {
            //show
            textView?.attributedText = redAttributesString(text: name, redText: text)
            raft.autoShow(.text(R.string.localizable.contentContainSensitiveWords()))
            return
        }
        inputResultHandler?(name)
        _ = textView.resignFirstResponder()
    }
    
}

extension AmongInputNotesView: UITextViewDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textViewDidEndEditing(_ textView: UITextView) {
//        inputContainerView.isHidden = true
//        isHidden = true
        fadeOut(duration: 0.25, completion: nil)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        fadeIn(duration: 0.25, completion: nil)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textFieldText = textView.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
        textView.textColor = .black
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + text.count
        hostNotesPlaceholderLabel.isHidden = count > 0
        return count <= 140
    }
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        
        textView.resignFirstResponder()
        
        guard let text = textView.text,
              text.count > 0 else {
            return true
        }
        
        textView.clear()
        return true
    }
}

extension AmongInputNotesView {
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
