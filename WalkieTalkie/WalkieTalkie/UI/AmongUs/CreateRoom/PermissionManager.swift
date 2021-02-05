//
//  PermissionManager.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 05/02/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import AppTrackingTransparency
import SwiftyUserDefaults
import SDCAlertView

class PermissionManager {
    static let shared = PermissionManager()
    weak var viewController: ViewController?
    
    enum RequestType: String {
        case appTracking
    }
    
    enum RequestStatus: Int {
        case notDetermined = 0
        case restricted = 1
        case denied = 2
        case authorized = 3
        //用户点击 later
        case later = 10
    }
        
    //FOR APP TRACKING
    func request(permission: RequestType, on viewController: ViewController, completion: CallBack?) {
        self.viewController = viewController
        //是否请求过
        let status = RequestStatus(rawValue: Defaults[key: DefaultsKeys.permissionRequestStatusKey(for: permission)]) ?? .notDetermined
        switch status {
        case .authorized, .denied, .restricted:
            completion?()
        case .notDetermined:
            switch permission {
            case .appTracking:
                requestAppTracking(completion: completion)
            }
        case .later:
            //检查是否再次申请
            switch permission {
            case .appTracking:
                requestAppTracking(completion: completion)
            }
        }
    }
    
    func requestAppTracking(completion: CallBack?) {
        if #available(iOS 14.0, *) {
            cdPrint("attrackingAuthorization state: \(ATTrackingManager.trackingAuthorizationStatus.rawValue)")
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .authorized:
                completion?()
            case .denied, .restricted:
                completion?()
            case .notDetermined:
                showAppTrackPermissionPreRequestAlert(with: completion)
            @unknown default:
                completion?()
            }
        } else {
            completion?()
        }
    }
    
    @available(iOS 14, *)
    private func showAppTrackPermissionPreRequestAlert(with completionHandler: CallBack?) {
        let requestTimes = Defaults[key: DefaultsKeys.permissionRequestTimes(for: .appTracking)]
        let factor = requestTimes < 4 ? 2 : 4
        let allowRequest: Bool = requestTimes % factor == 0
        Defaults[key: DefaultsKeys.permissionRequestTimes(for: .appTracking)] = requestTimes + 1
        guard allowRequest else {
            completionHandler?()
            return
        }
        let alert = AlertController(title: nil, message: nil)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alert.visualStyle = visualStyle
        
        let content = AppTrackingGuideView()
        alert.contentView.addSubview(content)
        content.allowTrackingHandler = { [weak alert] in
            alert?.dismiss(animated: false) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    cdPrint("requestTrackingAuthorization result state: \(status.rawValue)")
                    Defaults[key: DefaultsKeys.permissionRequestStatusKey(for: .appTracking)] = status.rawValue.int
                    mainQueueDispatchAsync(after: 0.1) {
                        completionHandler?()
                    }
                }
            }
        }
        content.laterHandler = { [weak alert] in
            alert?.dismiss(animated: true) {
                Defaults[key: DefaultsKeys.permissionRequestStatusKey(for: .appTracking)] = RequestStatus.later.rawValue
                
                Defaults[key: DefaultsKeys.permissionRequestUpdateTime(for: .appTracking)] = Date.currentDay
                completionHandler?()
            }
        }
        content.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        alert.visualStyle.width = Frame.Screen.width - 28 * 2
        alert.visualStyle.verticalElementSpacing = 0
        alert.visualStyle.contentPadding = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        alert.visualStyle.actionViewSize = CGSize(width: 0, height: 49)
        alert.view.backgroundColor = UIColor.black.alpha(0.6)
        alert.present()
    }
    
    
}
