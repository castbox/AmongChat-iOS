//
//  UIViewExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension UIView {
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
    
    var containingController: UIViewController? {
        
        var nextResponder: UIResponder? = self
        
        repeat {
            nextResponder = nextResponder?.next
            
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            
        } while nextResponder != nil
        return nil
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
//            gradientLayer.cornerRadius = 18

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

extension UIView {
    
    private struct AssociateKey {
        static var key = "redDotImageView"
    }
    
    func redDotOn(string: String? = nil, rightInset: CGFloat = 0, topInset: CGFloat = 0, diameter: CGFloat = 12) {
        guard redDotIV == nil else {
            return
        }
        let iv = UIImageView()
        iv.backgroundColor = "FA4E4E".color()
        iv.cornerRadius = diameter / 2
        addSubview(iv)
        iv.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(diameter)
            maker.top.equalToSuperview().inset(topInset)
            maker.trailing.equalToSuperview().inset(rightInset)
        }
        
        if let string = string {
            
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 12)
            l.text = string
            l.textColor = .white
            iv.addSubview(l)
            l.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 4.5, bottom: 0, right: 4))
            }
            
            let textWidth = l.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: diameter)).width.ceil
            let viewWidth = max(textWidth + 4 + 4, diameter)
            
            iv.snp.remakeConstraints { (maker) in
                maker.height.equalTo(diameter)
                maker.width.equalTo(viewWidth)
                maker.top.equalToSuperview().inset(topInset)
                maker.trailing.equalToSuperview().inset(-viewWidth + rightInset)
            }
            
        }
        
        redDotIV = iv
    }
    
    func redDotOff() {
        guard let iv = redDotIV else {
            return
        }
        
        iv.removeFromSuperview()
        redDotIV = nil
    }
    
    private weak var redDotIV: UIImageView? {
        get {
            return objc_getAssociatedObject(self, &AssociateKey.key) as? UIImageView
        }
        set {
            objc_setAssociatedObject(self, &AssociateKey.key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
