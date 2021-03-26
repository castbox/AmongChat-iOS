//
//  SmallSizeButton.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class SmallSizeButton: UIButton {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard max(bounds.width, bounds.height) < 30 else {
            return super.point(inside: point, with: event)
        }
        
        return bounds.insetBy(dx: -20, dy: -20).contains(point)
    }
    
}
