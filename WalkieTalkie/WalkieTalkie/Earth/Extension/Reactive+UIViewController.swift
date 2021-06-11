//
//  Reactive+UIViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import RxSwift
import RxCocoa

extension Reactive where Base: UIViewController {
    var viewDidAppear: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewDidAppear)).map { _ in }
        return ControlEvent(events: source)
    }
    
    var viewWillAppear: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewWillAppear(_:))).map { _ in }
        return ControlEvent(events: source)
    }
    
    var viewDidDisappear: ControlEvent<Void> {
        let source = methodInvoked(#selector(Base.viewDidDisappear(_:))).map { _ in }
        return ControlEvent(events: source)
    }
    
    var viewDidLayoutSubviews: ControlEvent<Void> {
        let source = methodInvoked(#selector(Base.viewDidLayoutSubviews)).map { _ in }
        return ControlEvent(events: source)
    }

    var viewWillDisappear: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewWillDisappear(_:))).map { _ in }
        return ControlEvent(events: source)
    }
    
    var dismiss: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.dismiss(animated:completion:))).map { _ in }
        return ControlEvent(events: source)
    }
}

extension Reactive where Base: UIButton {
    
    var isEnable: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(setter: Base.isEnabled)).map { _ in }
        return ControlEvent(events: source)
    }
}

extension Reactive where Base: UINavigationController {
    var pushViewController: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.pushViewController(_:animated:))).map { _ in }
        return ControlEvent(events: source)
    }
    
    var popViewController: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.popViewController(animated:))).map { _ in }
        return ControlEvent(events: source)
    }
}
