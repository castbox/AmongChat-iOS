//
//  GradientView.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/12/18.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import UIKit

/// 自定义GradientView解决CAGradientLayer不能跟随AutoLayout自动改变frame的问题
class GradientView: UIView {
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override var layer: CAGradientLayer {
        return super.layer as! CAGradientLayer
    }
}
