//
//  ObservableOptionalExtension.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/1/2.
//  Copyright © 2020 Guru. All rights reserved.
//

import Foundation
import RxSwift

protocol OptionalType {
    associatedtype Wrapped
    
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    var value: Wrapped? {
        return self
    }
}

extension ObservableType where E: OptionalType {
    func filterNil() -> Observable<E.Wrapped> {
        return self.flatMap { element -> Observable<E.Wrapped> in
            guard let value = element.value else {
                return Observable<E.Wrapped>.empty()
            }
            return Observable<E.Wrapped>.just(value)
        }
    }
    
    func errorOnNil(_ error: Error) -> Observable<E.Wrapped> {
        return self.flatMap { element -> Observable<E.Wrapped> in
            guard let value = element.value else {
                throw error
            }
            return Observable<E.Wrapped>.just(value)
        }
    }
}
