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

extension ObservableType where Element == Json {
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

extension ObservableType where Element == [[String: AnyObject]] {
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

extension ObservableType where Element == [String: AnyObject] {
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
    
    func mapToProcessedValue() -> Observable<Bool> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .mapTo(Entity.Processed.self)
            .map { $0?.processed ?? false }
    }
}

extension ObservableType where Element == Any {
    func mapToDataJson() -> Observable<[String: AnyObject]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                let empty: [String: AnyObject] = [:]
                guard let data = item as? [String: AnyObject] else {
                    return empty
                }
                return data
            }
    }
    
    func mapToDataKeyJsonValue() -> Observable<[String: AnyObject]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                guard let json = item as? [String: AnyObject],
                 let data = json["data"] as? [String: AnyObject] else {
                    return [:]
                }
                return data
            }
    }
    
    func mapToDataKeyListValue() -> Observable<[[String: AnyObject]]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                guard let json = item as? [String: AnyObject],
                 let data = json["data"] as? [[String: AnyObject]] else {
                    return []
                }
                return data
            }
    }
    
    func mapToListJson() -> Observable<[[String: AnyObject]]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                guard let listData = item as? [[String: AnyObject]] else {
                    return []
                }
                return listData
            }
    }
    
}


extension PrimitiveSequence where Trait == SingleTrait, Element == Any {
    func mapToDataJson() -> Single<[String: AnyObject]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                let empty: [String: AnyObject] = [:]
                guard let data = item as? [String: AnyObject] else {
                    return empty
                }
                return data
            }
    }
    
    func mapToDataKeyJsonValue() -> Single<[String: AnyObject]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                guard let json = item as? [String: AnyObject],
                 let data = json["data"] as? [String: AnyObject] else {
                    return [:]
                }
                return data
            }
    }
    
    func mapToDataKeyListValue() -> Single<[[String: AnyObject]]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                guard let json = item as? [String: AnyObject],
                 let data = json["data"] as? [[String: AnyObject]] else {
                    return []
                }
                return data
            }
    }
    
    func mapToListJson() -> Single<[[String: AnyObject]]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { item in
                guard let listData = item as? [[String: AnyObject]] else {
                    return []
                }
                return listData
            }
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == [[String: AnyObject]] {
    
    func mapTo<T: Decodable>(_ type: T.Type) -> Single<T?> {
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
extension PrimitiveSequence where Trait == SingleTrait, Element == [String: AnyObject] {
    
    func mapToProcessedValue() -> Single<Bool> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .mapTo(Entity.Processed.self)
            .map { $0?.processed ?? false }
    }
    
    func mapToListJson() -> Single<[[String: AnyObject]]> {
        return observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { json in
                guard let listData = json["list"] as? [[String: AnyObject]] else {
                    return []
                }
                return listData
            }
    }
    
    func mapTo<T: Decodable>(_ type: T.Type) -> Single<T?> {
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
