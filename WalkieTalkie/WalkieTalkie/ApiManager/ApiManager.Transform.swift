//
//  ApiManager.Transform.swift
//  Moya-Cuddle
//
//  Created by Wilson-Yuan on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
//import RxCocoa
import RxSwift

extension ObservableType where E == Json {
    func mapToDataJson() -> Observable<[String: AnyObject]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { json in
                let empty: [String: AnyObject] = [:]
                guard let data = json.jsonObj as? [String: AnyObject] else {
                    return empty
                }
                return data
            }
    }
    
    func mapToListJson() -> Observable<[[String: AnyObject]]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { json in
                guard let listData = json.jsonObj as? [[String: AnyObject]] else {
                    return []
                }
                return listData
            }
    }
}

extension ObservableType where E == [[String: AnyObject]] {
    func mapTo<T: Decodable>(_ type: T.Type) -> Observable<T?> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { value in
                var item: T?
                decoderCatcher {
                    item = try JSONDecoder().decodeAnyData(type, from: value) as T
                }
                return item
            }
    }
}

extension ObservableType where E == [String: AnyObject] {
    func mapToListJson() -> Observable<[[String: AnyObject]]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { json in
                guard let listData = json["list"] as? [[String: AnyObject]] else {
                    return []
                }
                return listData
            }
    }
    
    func mapTo<T: Decodable>(_ type: T.Type) -> Observable<T?> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { value in
                var item: T?
                decoderCatcher {
                    item = try JSONDecoder().decodeAnyData(type, from: value) as T
                }
                return item
            }
    }
}
