//
//  Castbox+Rx.swift
//  Castbox
//
//  Created by ChenDong on 2018/9/4.
//  Copyright © 2018年 Guru. All rights reserved.
//

import RxSwift

//extension URL: KingfisherCompatible {}
//
//extension KingfisherWrapper where Base == URL {
//
//    func retrieveImage() -> Observable<UIImage> {
//        return .create { (o) -> Disposable in
//            let task = KingfisherManager.shared.retrieveImage(with: self.base, options: nil, progressBlock: nil) { (image, error, _, _) in
//                if let image = image {
//                    o.onNext(image)
//                    o.onCompleted()
//                } else {
//                    let error = error ?? NSError(domain: "com.guru.castbox", code: 0, userInfo: [NSLocalizedDescriptionKey: "Can not get image"])
//                    o.onError(error)
//                }
//            }
//            return Disposables.create {
//                task.cancel()
//            }
//        }
//    }
//}

//extension URL {
//
//    func retrieveImage() -> Observable<UIImage> {
//        return .create { (o) -> Disposable in
//            let task = KingfisherManager.shared.retrieveImage(with: self, options: nil, progressBlock: nil) { (image, error, _, _) in
//                if let image = image {
//                    o.onNext(image)
//                    o.onCompleted()
//                } else {
//                    let error = error ?? NSError(domain: "com.guru.castbox", code: 0, userInfo: [NSLocalizedDescriptionKey: "Can not get image"])
//                    o.onError(error)
//                }
//            }
//            return Disposables.create {
//                task?.cancel()
//            }
//        }
//    }
//}
//
//typealias RequestEvent = ConsecutiveEvent
//
//extension RequestEvent {
//    var isFetching: Bool {
//        switch self {
//        case .start:
//            return true
//        default:
//            return false
//        }
//    }
//
//    var error: Error? {
//        switch self {
//        case .error(let e):
//            return e
//        default:
//            return nil
//        }
//    }
//
//    var content: T? {
//        switch self {
//        case .content(let e):
//            return e
//        default:
//            return nil
//        }
//    }
//}

//extension ObservableType {
//    
//    func asRequestObservable() -> Observable<RequestEvent<Self.E>> {
//        return .create { o -> Disposable in
//            return self
//                .do(onSubscribe: {
//                    o.onNext(.start)
//                })
//                .subscribe(onNext: { (e) in
//                    o.onNext(.content(e))
//                }, onError: { (e) in
//                    o.onNext(.error(e))
//                    o.onCompleted()
//                }, onCompleted: {
//                    o.onCompleted()
//                })
//        }
//    }
//}
