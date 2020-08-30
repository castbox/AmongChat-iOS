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
}
