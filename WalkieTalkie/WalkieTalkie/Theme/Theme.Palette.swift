//
//  Theme.Palette.swift
//  Castbox
//
//  Created by ChenDong on 2018/11/15.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit

extension Theme {
    
}

extension Theme {
    
    enum Suite {
        
        case A
        case B
        case B1
        
        case C
        case C1
        case C2
        case C3
        
        case D
        case D1
        case D2
        case D3
        case D4
        
        case E
        case E1
        case E2
        
        case F
        case F1
        case F2
        
        var value: (UIFont, UIColor) {
            
            func getValue(_ size: Font.Size, _ weight: Font.Weight, _ color: Theme.Color) -> (UIFont, UIColor) {
                return (.systemFont(ofSize: size.rawValue, weight: UIFont.Weight(rawValue: weight.rawValue)), color.value)
            }
            
            switch self {
            case .A:
                return getValue(.headline, .semibold, .textBlack)
                
            case .B:
                return getValue(.headline, .regular, .textBlack)
            case .B1:
                return getValue(.headline, .regular, .textWhite)
                
            case .C:
                return getValue(.title, .regular, .textBlack)
            case .C1:
                return getValue(.title, .regular, .textGray)
            case .C2:
                return getValue(.title, .regular, .main)
            case .C3:
                return getValue(.title, .regular, .textWhite)
                
            case .D:
                return getValue(.body, .regular, .textGray)
            case .D1:
                return getValue(.body, .regular, .textWhite)
            case .D2:
                return getValue(.body, .regular, .main)
            case .D3:
                return getValue(.body, .regular, .textWhite)
            case .D4:
                return getValue(.body, .semibold, .main)
                
            case .E:
                return getValue(.info, .regular, .textGray)
            case .E1:
                return getValue(.info, .regular, .textWhite)
            case .E2:
                return getValue(.info, .regular, .main)
                
            case .F:
                return getValue(.actionBar, .semibold, .textBlack)
            case .F1:
                return getValue(.actionBar, .semibold, .main)
            case .F2:
                return getValue(.actionBar, .semibold, .textGray)
            }
        }
    }
}

/**/
