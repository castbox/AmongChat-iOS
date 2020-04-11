//
//  ApiManager+Observable.swift
//  Moya-Cuddle
//
//  Created by Wilson-Yuan on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import Moya
import RxSwift

extension ApiManager: ReactiveCompatible {}

extension Reactive where Base: ApiManager {
    func request(_ target: ApiManager.WalkieTalkie, callbackQueue: DispatchQueue? = nil) -> Observable<Json> {
        return base.reactiveRequest(target, callbackQueue: callbackQueue)
    }
    
    func requestWithRawDataResponse(_ target: ApiManager.WalkieTalkie, callbackQueue: DispatchQueue? = nil) -> Observable<Data> {
        return base.reactiveRequestWithRawDataResponse(target, callbackQueue: callbackQueue)
    }
}

extension ApiManager {
    func reactiveRequest(_ target: ApiManager.WalkieTalkie, callbackQueue: DispatchQueue? = nil) -> Observable<Json> {
        return Observable.create { [weak self] observer in
            let cancellableToken = self?.request(target, callbackQueue: callbackQueue, success: { response in
                observer.onNext(response)
                observer.onCompleted()
            }, failure: { error in
                observer.onError(error)
            })
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }
    
    func reactiveRequestWithRawDataResponse(_ target: ApiManager.WalkieTalkie, callbackQueue: DispatchQueue? = nil) -> Observable<Data> {
        return Observable.create { [weak self] observer in
            let cancellableToken = self?.request(target, callbackQueue: callbackQueue, successWithRawData: { response in
                observer.onNext(response)
                observer.onCompleted()
            }, failure: { error in
                observer.onError(error)
            })
            return Disposables.create {
                cancellableToken?.cancel()
            }
        }
    }

}
