//
//  RoomToolsView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/5/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class RoomToolsView: UIView {
    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addCorners()
    }
}

extension RoomToolsView {
    func addCorners(topLeft: CGFloat = 17, topRight: CGFloat = 17, bottomLeft: CGFloat = 50, bottomRight: CGFloat = 50) {
        let topLeftRadius = CGSize(width: topLeft, height: topLeft)
        let topRightRadius = CGSize(width: topRight, height: topRight)
        let bottomLeftRadius = CGSize(width: bottomLeft, height: bottomLeft)
        let bottomRightRadius = CGSize(width: bottomRight, height: bottomRight)
        let maskPath = UIBezierPath(shouldRoundRect: bounds, topLeftRadius: topLeftRadius, topRightRadius: topRightRadius, bottomLeftRadius: bottomLeftRadius, bottomRightRadius: bottomRightRadius)
        guard let layer = self.layer as? CAShapeLayer else {
            return
        }
        layer.fillColor = "221F1F".color().cgColor
        layer.path = maskPath.cgPath
//        let shape = CAShapeLayer()
//        shape.path = maskPath.cgPath
//        layer.mask = shape
    }
}
