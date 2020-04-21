//
//  Scheduler.swift
//  Quotes
//
//  Created by 江嘉睿 on 2020/4/15.
//  Copyright © 2020 Guru Network Limited Inc. All rights reserved.
//

import RxSwift
import RxCocoa

struct Scheduler {
    static let timerScheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "scanner.timer")
    
    
    /// Scheduler with dispatch qos
    static let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    
    static let uerInitiatedScheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    
    static let interativeScheduler = ConcurrentDispatchQueueScheduler(qos: .userInteractive)
}
