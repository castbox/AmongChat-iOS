//
//  AmongChat.Room.QueueManager.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 03/02/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension AmongChat.Room {
    class QueueManager<T: Hashable> {
        typealias CallBack = (Bool) -> Void
        typealias ExecuteHandler = (T) -> Void

        private struct PlayRequest {
            let item: T
            let executeHandler: ExecuteHandler?
            let callback: CallBack?
        }

        private let bag = DisposeBag()
        private let parseScheduler = SerialDispatchQueueScheduler(qos: .userInteractive)
        
        private let resourceQueue = PublishSubject<PlayRequest>()
        private let ready = BehaviorSubject<Bool>(value: false)
        private var currentRequest: PlayRequest?
        let dependencyReadyBehavior = BehaviorRelay<Bool>(value: false)
        private var requests: [PlayRequest] = []
        
        private var isDependencyExecutingNow: Bool {
            return dependencyReadyBehavior.value
        }
        
        private var isReayNow: Bool {
            return (try? ready.value()) ?? false
        }

        init() {
            dependencyReadyBehavior
                .debug("QueuedManager:dependencyReadyBehavior:isReady", trimOutput: false)
                .filter { !$0 }
                .subscribe(onNext: { [weak self] _ in
                    guard let `self` = self,
                        !self.requests.isEmpty,
                        !self.isReayNow
                     else { return }
                    self.ready.onNext(true)
                })
                .disposed(by: bag)
            
            let readySignal = Observable.combineLatest(ready, dependencyReadyBehavior)
                .map { (ready, dependencyReady) -> Bool in
                    return ready && !dependencyReady
                }
                .debug("QueuedManager:readySignal:isReady", trimOutput: false)
                .filter { $0 }
                .flatMap { [weak self] value -> Observable<Bool> in
                    guard let `self` = self,
                        !self.requests.isEmpty else { return .empty() }
                    return Observable.just(value)
                }

            Observable.zip(resourceQueue, readySignal) { (ele1, ele2) -> PlayRequest in
                cdPrint("QueuedManager:zip:isReady: \(ele2)")
                    return ele1
                }
                .debug("QueuedManager:readySignal:execute", trimOutput: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (request) in
                    guard let `self` = self else { return }
                    self.currentRequest = request
                    request.executeHandler?(request.item)
                })
                .disposed(by: bag)
        }
        
        func bind(_ dependency: Observable<Bool>) {
            dependency.bind(to: dependencyReadyBehavior)
                .disposed(by: bag)
        }
        
        func onComplete() {
//            ready.onNext(true)
            //移除当前任务
            let completedRequest = currentRequest
            requests.removeElement(ifExists: {
                $0.item.hashValue == completedRequest?.item.hashValue
            })
            completedRequest?.callback?(true)
            //当外部依赖不执行时
            if !isDependencyExecutingNow {
                //检查是否有任务
                ready.onNext(!requests.isEmpty)
            } else {
                ready.onNext(false)
            }
        }
        
        func enqueue(_ item: T, executeHandler: ExecuteHandler?, completionHandler: CallBack? = nil) {

            let request = PlayRequest(item: item, executeHandler: executeHandler, callback: completionHandler)

            requests.append(request)

            resourceQueue.onNext(request)
            //if isReady is false, then set to true
            if let isReady = try? ready.value(),
                !isReady, !isDependencyExecutingNow {
                //prepare to start the tasks
                ready.onNext(true)
            }
        }
        
        func completionTaskObservable() -> Observable<Bool> {
            return ready.asObserver()
                .map { !$0 }
        }
    }
}
