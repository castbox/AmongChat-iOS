//
//  UITextFieldExtension.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/20.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import UIKit

extension UITextField {
    
    func clearText() {
        clear()
        sendActions(for: .editingChanged)
    }
    
}
