//
//  Notice.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct Notice {
    
}

protocol UnhandledNoticeStatusObservableProtocal: UIViewController {
    var hasUnhandledNotice: BehaviorRelay<Bool> { get }
}
