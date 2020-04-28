//
//  UIViewFrameExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/28.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension UIView {
    
    var frameX: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
        get {
            self.frame.origin.x
        }
    }
    
    var frameY: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
        get {
            return self.frame.origin.y
        }
    }
    
    var frameOrigin: CGPoint {
        set {
            var frame: CGRect = self.frame
            frame.origin = newValue
            self.frame = frame
        }
        get {
            self.frame.origin
        }
    }
    
    var frameWidth: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
        get {
            self.frame.width
        }
    }
    var frameHeight: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
        get {
            self.frame.height
            
        }
    }
    
    var frameSize: CGSize {
        set {
            var frame: CGRect = self.frame
            frame.size = newValue
            self.frame = frame
        }
        get {
            return self.frame.size
            
        }
    }
    
    var frameXAndWidth: CGFloat {
        set {
            var rect: CGRect = self.frame
            rect.origin.x = newValue - rect.size.width
            self.frame = rect
        }
        get {
            self.frame.origin.x+self.frame.size.width
        }
    }
    var frameYAndHeight: CGFloat {
        set {
            var rect: CGRect = self.frame
            rect.origin.y = newValue - rect.size.height
            self.frame = rect
        }
        get {
            self.frame.origin.y+self.frame.size.height
        }
    }
    var boundsCenter: CGPoint {
        CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
    }
    
    var boundsCenterX: CGFloat {
        self.bounds.size.width/2
    }
    var boundsCenterY: CGFloat {
        self.bounds.size.width/2
    }
    
    var boundsWidth: CGFloat {
        self.bounds.size.width
    }
    
    var boundsHeight: CGFloat {
        self.bounds.size.height
    }
    
    var centerX: CGFloat {
        set {
            var point: CGPoint = self.center
            point.x = newValue
            self.center = point
        }
        get {
            self.center.x
        }
    }
    var centerY: CGFloat {
        set {
            var point: CGPoint = self.center
            point.y = newValue
            self.center = point
        }
        get {
            self.center.y
        }
    }
    
    ///////////////////
    
    var leftTop: CGPoint {
        set {
            self.frameOrigin = newValue
        }
        get {
            self.frameOrigin
        }
    }
    var leftCenter: CGPoint {
        set {
            self.center = CGPoint(x: newValue.x + self.frameWidth/2, y: newValue.y)
        }
        get {
            CGPoint(x: self.frameX, y: self.centerY)
        }
    }
    var leftBottom: CGPoint {
        set {
            self.center = CGPoint(x: newValue.x+self.frameWidth/2, y: newValue.y-self.frameHeight/2)
        }
        get {
            return CGPoint(x: self.frameX, y: self.centerY+self.frameHeight/2)
        }
    }
    var topCenter: CGPoint {
        set {
            self.center = CGPoint(x: newValue.x, y: newValue.y+self.frameHeight/2)
        }
        get {
            return CGPoint(x: self.centerX, y: self.frameY)
        }
    }
    
    var bottomCenter: CGPoint {
        set {
            self.center = CGPoint(x: newValue.x, y: newValue.y-self.frameHeight/2)
        }
        get {
            CGPoint(x: self.centerX, y: self.frameYAndHeight)
        }
    }
    var rightTop: CGPoint {
        set {
            self.center = CGPoint(x: newValue.x-self.frameWidth/2, y: newValue.y+self.frameHeight/2)
        }
        get {
            CGPoint(x: self.frameXAndWidth, y: self.frameY)
        }
    }
    var rightCenter: CGPoint {
        set {
            self.center = CGPoint(x: newValue.x-self.frameWidth/2, y: newValue.y)
        }
        get {
            CGPoint(x: self.frameXAndWidth, y: self.centerY)
        }
    }
    var rightBottom: CGPoint {
        set {
            self.center = CGPoint(x: newValue.x-self.frameWidth/2, y: newValue.y-self.frameHeight/2)
        }
        get {
            return CGPoint(x: self.frameXAndWidth, y: self.frameYAndHeight)
        }
    }
    
    var left: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
        get {
            self.frame.origin.x
        }
    }
    var top: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
        get {
            self.frame.origin.y
        }
    }
    var right: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue - frame.size.width
            self.frame = frame
        }
        get {
            self.frame.origin.x+self.frame.size.width
        }
    }
    var bottom: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue - frame.size.height
            self.frame = frame
        }
        get {
            self.frame.origin.y + self.frame.size.height
        }
    }
    var width: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
        get {
            self.frame.size.width
        }
    }
    var height: CGFloat {
        set {
            var frame: CGRect = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
        get {
            self.frame.size.height
        }
    }
    var origin: CGPoint {
        set {
            var frame: CGRect = self.frame
            frame.origin = newValue
            self.frame = frame
        }
        get {
            self.frame.origin
        }
    }
    var size: CGSize {
        set {
            var frame: CGRect = self.frame
            frame.size = newValue
            self.frame = frame
        }
        get {
            self.frame.size
        }
    }
    
}
