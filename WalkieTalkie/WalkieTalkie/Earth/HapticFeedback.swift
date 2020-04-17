//
//  HapticFeedback.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class HapticFeedback {
    
    @available(iOS 10.0, *)
    public struct Impact {
        
        fileprivate static var generator: UIImpactFeedbackGenerator?
        
        public static func light() {
            impactOccurred(.light)
        }
        
        public static func medium() {
            impactOccurred(.medium)
        }
        
        public static func heavy() {
            impactOccurred(.heavy)
        }
        
        fileprivate static func impactOccurred(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
            generator = UIImpactFeedbackGenerator(style: style)
            generator?.prepare()
            generator?.impactOccurred()
        }
        
    }
    
    @available(iOS 10.0, *)
    public struct Selection {
        
        fileprivate static var generator: UISelectionFeedbackGenerator = {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            
            return generator
        }()
        
        
        public static func selectionSound() {
//            playSound(forResource: "selection")
        }
        
        
        public static func selection() {
            generator.selectionChanged()
            generator.prepare()
        }
        
    }
    
}
