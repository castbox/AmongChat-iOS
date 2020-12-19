//
//  AmongInputCodeView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SwifterSwift

class AmongInputCodeView: XibLoadableView {

    
    @IBOutlet weak var textField: PaddingTextField!
    
    @IBOutlet weak var inputContainerView: UIView!
        
    @IBOutlet weak var northAmericaButton: UIButton!
    @IBOutlet weak var asiaButton: UIButton!
    @IBOutlet weak var europeButton: UIButton!
    
    private var locationService: Entity.AmongUsZone = .northAmercia {
        didSet {
            northAmericaButton.setBackgroundImage("D8D8D8".color().image, for: .normal)
            asiaButton.setBackgroundImage("D8D8D8".color().image, for: .normal)
            europeButton.setBackgroundImage("D8D8D8".color().image, for: .normal)
            
            switch locationService {
            case .northAmercia:
                northAmericaButton.setBackgroundImage("FFF000".color().image, for: .normal)
            case .asia:
                asiaButton.setBackgroundImage("FFF000".color().image, for: .normal)
            case .europe:
                europeButton.setBackgroundImage("FFF000".color().image, for: .normal)
            }
        }
    }
    
    var inputResultHandler: ((String, Entity.AmongUsZone) -> Void)?

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
        locationService = .northAmercia
    }
    
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    @IBAction func serviceLocationAction(_ sender: UIButton) {
        guard let location = Entity.AmongUsZone(rawValue: sender.tag) else {
            return
        }
        locationService = location
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        _ = textField.resignFirstResponder()

    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        _ = textField.resignFirstResponder()
        guard let code = textField.text?.trimmed else {
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
        return count <= 10
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
