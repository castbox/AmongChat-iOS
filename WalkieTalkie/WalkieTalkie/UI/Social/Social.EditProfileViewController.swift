//
//  Social.EditProfileViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    class EditProfileViewController: ViewController {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var userNameTitle: UILabel = {
            let lb = UILabel()
            lb.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            return lb
        }()
        
        private lazy var userNameInputField: UITextField = {
            let f = UITextField()
            
            return f
        }()
        
        private lazy var ageTitle: UILabel = {
            let lb = UILabel()
            lb.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            return lb
        }()
        
        private lazy var ageInputField: UITextField = {
            let f = UITextField()
            return f
        }()
        
        private lazy var birthdayPicker: UIDatePicker = {
            let p = UIDatePicker()
            p.datePickerMode = .date
            p.date = Date()
            p.maximumDate = Date()
            p.minimumDate = Date(timeIntervalSince1970: 0)
            p.addTarget(self, action: #selector(onBirthdaySelected(sender:)), for: .primaryActionTriggered)
            return p
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
        }
        
        @objc
        private func onBirthdaySelected(sender: UIDatePicker) {
            
        }
        
    }
}

extension Social.EditProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == ageInputField {
            return false
        } else {
            return true
        }
    }
    
}
