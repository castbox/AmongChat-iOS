//
//  Frame.swift
//  Cuddle
//
//  Created by Marry on 2019/6/19.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import DeviceKit

struct Frame {
    /// 屏幕相关
    struct Screen {
        static let width = UIScreen.main.bounds.size.width
        static let height = UIScreen.main.bounds.size.height
        static let bounds = UIScreen.main.bounds
    }
    
    struct Height {
        
        static var isXStyle: Bool {
            let xStyleDevices: [Device] = [
                .iPhoneX,
                .iPhoneXS,
                .iPhoneXSMax,
                .iPhoneXR,
                .iPhone11,
                .iPhone11Pro,
                .iPhone11ProMax,
                .simulator(.iPhoneX),
                .simulator(.iPhoneXS),
                .simulator(.iPhoneXSMax),
                .simulator(.iPhoneXR),
                .simulator(.iPhone11),
                .simulator(.iPhone11Pro),
                .simulator(.iPhone11ProMax),
            ]
            return xStyleDevices.contains(Device.current)
        }
        
        static var safeAeraTopHeight: CGFloat {
            return isXStyle ? 44: 20
        }
        
        static var safeAeraBottomHeight: CGFloat {
            return isXStyle ? 34: 0
        }
        
        static var bottomBar: CGFloat {
            return 49 + safeAeraBottomHeight
        }
        
        static var navigation: CGFloat {
            return isXStyle ? 88: 64
        }
        
        static var deviceDiagonalIsMinThan4_7: Bool {
            return Device.current.diagonal < 4.7
        }
        
        static var deviceDiagonalIs4_7: Bool {
            return Device.current.diagonal == 4.7
        }
        
        static var deviceDiagonalIsMinThan5_5: Bool {
            return Device.current.diagonal < 5.5
        }
        
        //iphonex
        static var deviceDiagonalIsMinThan5_8: Bool {
            return Device.current.diagonal <= 5.8
        }
    }
    
    /// 比例
    struct Scale {
        /// scale width
        static func width(_ origin: CGFloat) -> CGFloat {
            return Frame.Screen.width * origin / 375.0
        }
        /// scale height
        static func height(_ origin: CGFloat) -> CGFloat {
            return Frame.Screen.height * origin / 812
        }
        /// size rectangle
        static func size(_ originWidth: CGFloat, _ originHeight: CGFloat) -> CGSize {
            return CGSize(width: width(originWidth), height: height(originHeight))
        }
        /// size square
        static func size(_ origin: CGFloat) -> CGSize {
            return CGSize(width: width(origin), height: width(origin))
        }
    }
    
    struct CornerRadius {
        static let message: CGFloat = 12
    }
    
}
