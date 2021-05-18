//
//  BaseNotificationBannerExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 08/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import RxSwift
import RxCocoa

extension BaseNotificationBanner {
    
    private struct AssociateKey {
        static var key = "isDismissedByTapEvent"
    }
    
    var isDismissedByTapEvent: Bool {
        get {
            let number = objc_getAssociatedObject(self, &AssociateKey.key) as? NSNumber
            return number?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociateKey.key, NSNumber(booleanLiteral: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

extension Reactive where Base: BaseNotificationBanner {
    var notificationBannerDidDisappear: Observable<()> {
        return BaseNotificationBannerDelegateProxy.proxy(for: base)
            .notificationBannerDidDisappearSubject
            .asObserver()
    }
    
    var notificationBannerWillDisappear: Observable<()> {
        return BaseNotificationBannerDelegateProxy.proxy(for: base)
            .notificationBannerWillDisappearSubject
            .asObserver()
    }
}

class BaseNotificationBannerDelegateProxy: DelegateProxy<BaseNotificationBanner, NotificationBannerDelegate>, DelegateProxyType, NotificationBannerDelegate {
    static func registerKnownImplementations() {
        self.register { BaseNotificationBannerDelegateProxy(parentObject: $0) }
    }
    
    static func currentDelegate(for object: BaseNotificationBanner) -> NotificationBannerDelegate? {
        return object.delegate
    }
    
    static func setCurrentDelegate(_ delegate: NotificationBannerDelegate?, to object: BaseNotificationBanner) {
        object.delegate = delegate
    }
    
    lazy var notificationBannerDidDisappearSubject = PublishSubject<()>()
    lazy var notificationBannerWillDisappearSubject = PublishSubject<()>()

    func notificationBannerWillAppear(_ banner: BaseNotificationBanner) {
        
    }
    
    func notificationBannerDidAppear(_ banner: BaseNotificationBanner) {
        
    }
    
    func notificationBannerWillDisappear(_ banner: BaseNotificationBanner) {
        notificationBannerWillDisappearSubject.onNext(())
        notificationBannerWillDisappearSubject.onCompleted()
    }
    
    func notificationBannerDidDisappear(_ banner: BaseNotificationBanner) {
        notificationBannerDidDisappearSubject.onNext(())
        notificationBannerDidDisappearSubject.onCompleted()
    }
    
    init(parentObject: BaseNotificationBanner) {
        super.init(parentObject: parentObject, delegateProxy: BaseNotificationBannerDelegateProxy.self)
    }
    
}
