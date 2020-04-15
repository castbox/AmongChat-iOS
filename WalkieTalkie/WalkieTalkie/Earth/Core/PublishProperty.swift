//
//  PublishProperty.swift
//  Castbox
//
//  Created by ChenDong on 2018/5/4.
//  Copyright © 2018年 Guru. All rights reserved.
//

import RxSwift

class PublishProperty<T>: PropertyProtocol {
    
    typealias Change = DynamicProperty<T>.Change
    
    var value: T {
        get {
            return property.value
        }
        set {
            let oldValue = self.value
            willSetSubject.onNext(.init(oldValue, newValue))
            property.value = newValue
            didSetSubject.onNext(.init(oldValue, self.value))
        }
    }
    
    private var property: DynamicProperty<T>
    private let willSetSubject = PublishSubject<Change>()
    private let didSetSubject = PublishSubject<Change>()
    private let serialDisposable = SerialDisposable()
    
    init(property: DynamicProperty<T>) {
        self.property = property
    }
    
    private func reset(property: DynamicProperty<T>) {
        let oldValue = self.value
        willSetSubject.onNext(.init(oldValue, property.value))
        self.property = property
        didSetSubject.onNext(.init(oldValue, self.value))
    }
    
    func willSet() -> Observable<Change> {
        return willSetSubject
    }
    
    func didSet() -> Observable<Change> {
        return didSetSubject
    }
    
    func publish() -> Observable<T> {
        return didSetSubject.map({ $0.new })
    }
    
    func replay() -> Observable<T> {
        return publish().startWith(value)
    }
    
    @discardableResult
    func receive(_ properties: Observable<DynamicProperty<T>>) -> Self {
        weak var welf = self
        self.serialDisposable.disposable = properties
            .subscribe(onNext: { (p) in
                guard let `self` = welf else { return }
                self.reset(property: p)
            })
        return self
    }
    
    deinit {
        serialDisposable.dispose()
    }
}

extension DynamicProperty {
    func asPublishProperty() -> PublishProperty<T> {
        return PublishProperty<T>(property: self)
    }
}

