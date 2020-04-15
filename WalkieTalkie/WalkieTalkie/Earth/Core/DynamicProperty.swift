//
//  DynamicProperty.swift
//  Castbox
//
//  Created by ChenDong on 2018/4/28.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation

protocol PropertyProtocol {
    associatedtype T
    var value: T { get set }
}

class DynamicProperty<T>: PropertyProtocol {
    
    struct Change {
        let old: T
        let new: T
        
        init(_ old: T, _ new: T) {
            self.old = old
            self.new = new
        }
    }
    
    private let getter: () -> T
    private let setter: (T) -> Void

    private let willSet: ((Change) -> Void)?
    private let didSet: ((Change) -> Void)?
    
    var value: T {
        get {
            return getter()
        }
        set {
            let oldValue = getter()
            willSet?(.init(oldValue, newValue))
            setter(newValue)
            didSet?(.init(oldValue, getter()))
        }
    }
    
    init(getter: @escaping () -> T,
         setter: @escaping (T) -> Void,
         willSet: ((Change) -> Void)? = nil,
         didSet: ((Change) -> Void)? = nil) {
        
        self.getter = getter
        self.setter = setter
        self.willSet = willSet
        self.didSet = didSet
    }
    
    @discardableResult
    func willSet(_ added: @escaping (Change) -> Void) -> DynamicProperty<T> {
        let oldWillSet = self.willSet
        let newWillSet = { (c: Change) -> Void in
            oldWillSet?(c)
            added(c)
        }
        return DynamicProperty(getter: self.getter,
                               setter: self.setter,
                               willSet: newWillSet,
                               didSet: self.didSet)
    }
    
    @discardableResult
    func didSet(_ added: @escaping (Change) -> Void) -> DynamicProperty<T> {
        let oldDidSet = self.didSet
        let newDidSet = { (c: Change) -> Void in
            oldDidSet?(c)
            added(c)
        }
        return DynamicProperty(getter: self.getter,
                               setter: self.setter,
                               willSet: self.willSet,
                               didSet: newDidSet)
    }
    
    func asDynamicProperty() -> DynamicProperty<T> {
        return self
    }
}

extension PropertyProtocol {
    
    static func stored(_ initial: T) -> DynamicProperty<T> {
        var value = initial
        return DynamicProperty(
            getter: { value },
            setter: { value = $0 }
        )
    }
    
    func asDynamicProperty() -> DynamicProperty<T> {
        var this = self
        return DynamicProperty<T>(
            getter: { this.value },
            setter: { this.value = $0 }
        )
    }
}
