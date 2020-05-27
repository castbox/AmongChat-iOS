//
//  UIViewExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension UIView{
    func roundCorners(topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0) {
        let topLeftRadius = CGSize(width: topLeft, height: topLeft)
        let topRightRadius = CGSize(width: topRight, height: topRight)
        let bottomLeftRadius = CGSize(width: bottomLeft, height: bottomLeft)
        let bottomRightRadius = CGSize(width: bottomRight, height: bottomRight)
        let maskPath = UIBezierPath(shouldRoundRect: bounds, topLeftRadius: topLeftRadius, topRightRadius: topRightRadius, bottomLeftRadius: bottomLeftRadius, bottomRightRadius: bottomRightRadius)
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        layer.mask = shape
    }
}

extension UIView {
    func addInnerShadow(to edges: [UIRectEdge], radius: CGFloat = 3.0, opacity: Float = 0.6, color: CGColor = UIColor.black.cgColor) {

        let fromColor = color
        let toColor = UIColor.clear.cgColor
        let viewFrame = self.frame
        for edge in edges {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [fromColor, toColor]
            gradientLayer.opacity = opacity
            gradientLayer.shadowRadius = 18

            switch edge {
            case .top:
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                gradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: viewFrame.width, height: radius)
            case .bottom:
                gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
                gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
                gradientLayer.frame = CGRect(x: 0.0, y: viewFrame.height - radius, width: viewFrame.width, height: radius)
            case .left:
                gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
                gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
                gradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: radius, height: viewFrame.height)
            case .right:
                gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.5)
                gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.5)
                gradientLayer.frame = CGRect(x: viewFrame.width - radius, y: 0.0, width: radius, height: viewFrame.height)
            default:
                break
            }
            self.layer.addSublayer(gradientLayer)
        }
    }

    func removeAllShadows() {
        if let sublayers = self.layer.sublayers, !sublayers.isEmpty {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
    }
}

//class EdgeShadowLayer: CAGradientLayer {
//
//    public enum Edge {
//        case Top
//        case Left
//        case Bottom
//        case Right
//    }
//
//    public init(forView view: UIView,
//                edge: Edge = Edge.Top,
//                shadowRadius radius: CGFloat = 20.0,
//                toColor: UIColor = UIColor.white,
//                fromColor: UIColor = UIColor.black) {
//        super.init()
//        self.colors = [fromColor.cgColor, toColor.cgColor]
//        self.shadowRadius = radius
//
//        let viewFrame = view.frame
//
//        switch edge {
//            case .Top:
//                startPoint = CGPoint(x: 0.5, y: 0.0)
//                endPoint = CGPoint(x: 0.5, y: 1.0)
//                self.frame = CGRect(x: 0.0, y: 0.0, width: viewFrame.width, height: shadowRadius)
//            case .Bottom:
//                startPoint = CGPoint(x: 0.5, y: 1.0)
//                endPoint = CGPoint(x: 0.5, y: 0.0)
//                self.frame = CGRect(x: 0.0, y: viewFrame.height - shadowRadius, width: viewFrame.width, height: shadowRadius)
//            case .Left:
//                startPoint = CGPoint(x: 0.0, y: 0.5)
//                endPoint = CGPoint(x: 1.0, y: 0.5)
//                self.frame = CGRect(x: 0.0, y: 0.0, width: shadowRadius, height: viewFrame.height)
//            case .Right:
//                startPoint = CGPoint(x: 1.0, y: 0.5)
//                endPoint = CGPoint(x: 0.0, y: 0.5)
//                self.frame = CGRect(x: viewFrame.width - shadowRadius, y: 0.0, width: shadowRadius, height: viewFrame.height)
//        }
//    }
//
//    required public init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
