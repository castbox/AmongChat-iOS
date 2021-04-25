//
//  UIImageExtension.swift
//  Castbox
//
//  Created by ChenDong on 2017/6/22.
//  Copyright © 2017年 Guru. All rights reserved.
//

import UIKit
import CoreImage
import CoreGraphics

extension UIImage {
    
    func getAverageColor(_ handler: @escaping (UIColor) -> Void) {
        
        /*
        getColors(completionHandler: { colors in
            let color = colors.primaryColor!
            handler(color)
        })
        */
        DispatchQueue.main.async {
            
            var bitmap = [UInt8](repeating: 0, count: 4)
            
            if #available(iOS 9.0, *) {
                // Get average color.
                let context = CIContext()
                let inputImage: CIImage = self.ciImage ?? CoreImage.CIImage(cgImage: self.cgImage!)
                let extent = inputImage.extent
                let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
                let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
                let outputImage = filter.outputImage!
                let outputExtent = outputImage.extent
                assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
                
                // Render to bitmap.
                context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
            } else {
                // Create 1x1 context that interpolates pixels when drawing to it.
                let context = CGContext(data: &bitmap, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                let inputImage = self.cgImage ?? CIContext().createCGImage(self.ciImage!, from: self.ciImage!.extent)
                
                // Render to bitmap.
                context.draw(inputImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            
            // Compute result.
            let result = UIColor(red: CGFloat(bitmap[0]) / 255.0,
                                 green: CGFloat(bitmap[1]) / 255.0,
                                 blue: CGFloat(bitmap[2]) / 255.0,
                                 alpha: CGFloat(bitmap[3]) / 255.0).darken(by: 130/255.0)

            DispatchQueue.main.async {
                handler(result)
            }
        }
 /**/
    }
    
    func scale(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func resize(size: CGSize? = nil, color: UIColor? = nil) -> UIImage? {
        
        var size = size
        if size == nil {
            size = self.size
        }
        let rect = CGRect(origin: CGPoint(), size: size!)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        
        if let color = color {
            color.setFill()
        }
        UIRectFill(rect)
        
        draw(in: rect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result
    }
    
    // 像素对齐
    func resize(size: CGSize? = nil) -> UIImage? {
        
        let backColor: UIColor
        if Settings.shared.theme.value == .dark {
            backColor = Theme.Color.backgroundBlack.value
        } else {
            backColor = Theme.Color.backgroundWhite.value
        }
        
        return resize(size: size, color: backColor)
    }
    
    // http://www.jianshu.com/p/f970872fdc22
    func drawRectWithRoundedCorner(radius: CGFloat, sizetoFit: CGSize) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: sizetoFit)
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners,
                                cornerRadii: CGSize(width: radius, height: radius))
        path.addClip()
        draw(in: rect)
        
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return output ?? self
    }
    
    func aspectFillImage(filling targetSize: CGSize, withCorner radius: CGFloat) -> UIImage {
        
        let sizeRatio = size.width / size.height
        let targetSizeRatio = targetSize.width / targetSize.height
        var targetRect = CGRect(origin: .zero, size: size)
        
        if targetSizeRatio > sizeRatio {
            // targetSize 宽长，变化 height 和 origin.y
            targetRect.size.height = size.width / targetSizeRatio
            targetRect.origin.y = (targetRect.size.height - size.height) / 2
        } else {
            // targetSize 竖长，变化 width 和 origin.x
            targetRect.size.width = size.height * targetSizeRatio
            targetRect.origin.x = (targetRect.size.width - size.width) / 2
        }
        
        let targetRadius = targetRect.width / targetSize.width * radius
        
        UIGraphicsBeginImageContextWithOptions(targetRect.size, false, self.scale)
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: targetRect.size), byRoundingCorners: .allCorners,
                                cornerRadii: CGSize(width: targetRadius, height: targetRadius))
        path.addClip()
        draw(in: CGRect(origin: targetRect.origin, size: size))
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return output ?? self
    }
    
    static func image(with color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        if let context = UIGraphicsGetCurrentContext() {
            
            context.setFillColor(color.cgColor)
            context.fill(rect)
            
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return colorImage
        }
        return nil
    }
    
    static func roundImage(withCorner radius: CGFloat, color: UIColor) -> UIImage? {
        let size = CGSize(width: 2 * radius, height: 2 * radius)
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        if let context = UIGraphicsGetCurrentContext() {

            context.setFillColor(color.cgColor)
            context.fillEllipse(in: rect)
            
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return colorImage
        }
        return nil
    }
    
    static func resizableImage(withCorner radius: CGFloat, color: UIColor) -> UIImage? {
        let image = roundImage(withCorner: radius, color: color)
        return image?.resizableImage(withCapInsets: UIEdgeInsets(top: radius, left: radius, bottom: radius, right: radius), resizingMode: .stretch)
    }
}
