//
//  PublishValue.swift
//  Castbox
//
//  Created by ChenDong on 2019/2/23.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import RxSwift

/**
 解决多状态同步变化信号发送时序问题，线程不安全
 
 假设一个对象有 A,B,C,D 4 个状态，初始值为 a0, b0, c0, d0
 
 当有一个外部因素导致了 a0 -> a1，c0 -> c1
 
 那么监听 A 变化的回调中（KVO 或 Rx），读取 C 可能还是 c0，而不是 c1
 
 为了解决这种问题，对于成批变化的状态量，在所有状态变化完成之后再通知 Observer
 
 具体的写法如:
 ```
 A.value = a1
 C.value = c1
 A.publish()
 C.publish()
 ```
 或者通过 `sep(_:publishAfter:)` 函数
 ```
 A.sep(a1) {
    C.sep(c1)
 }
 ```
 */
final class PublishValue<E> {
    
    var value: E
    private let subject = PublishSubject<E>()
    
    init(_ v: E) {
        self.value = v
    }
    
    func publish() {
        subject.onNext(value)
    }
    
    func asObservable() -> Observable<E> {
        return subject.startWith(value)
    }

    /// 先把自己的 value 赋值，然后在 block 之后进行 publish。sep 表示 set...publish...
    func sep(_ value: E, pubishAfter block: () -> Void = {} ) {
        self.value = value
        block()
        publish()
    }
}
