//
//  Cuddle.ApiManager.swift
//  Moya-Cuddle
//
//  Created by Wilson on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import Moya
import Alamofire
import RxSwift

fileprivate func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJson = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJson, options: .prettyPrinted)
        return prettyData
    } catch {
        return data
    }
}

struct ResponseError: Error, CustomStringConvertible {
    static let jsonMapping = ResponseError(message: "jsonMapping error", code: .jsonMapping)
    
    enum Code: Int {
        case serviceError = 0, httpError = 1
        case timeout = 2, cancelled = 3, unknow = 4
        case invalidParams = 5
        case parseResponseError
        case jsonMapping
    }
    
    let message: String
    let code: Code
    
    var description: String {
        return "errorCode: \(code), message: \(message)"
    }
}

class ApiManager<T: TargetType> {
//    static let `default` = ApiManager()
//    private let manager: Session
    private let provider: MoyaProvider<T>
    
    init() {
        
//        manager = Session(
//            configuration: URLSessionConfiguration.default,
//            delegate: SessionDelegate()
//        )
        
        #if DEBUG
//        let stubBehavior = MoyaProvider<Cuddle>.immediatelyStub
        let stubBehavior = MoyaProvider<T>.neverStub
        #else
        let stubBehavior = MoyaProvider<T>.neverStub
        #endif
//        NetworkLoggerPlugin.Configuration(formatter: JSONResponseDataFormatter, logOptions: <#T##NetworkLoggerPlugin.Configuration.LogOptions#>)
        provider = MoyaProvider<T>(
            stubClosure: stubBehavior,
//            manager: manager,
            plugins: [
                NetworkLoggerPlugin(),
                RequestHandlingPlugin(),
            ]
        )
    }
    
//    @discardableResult
//    static func request(
//        _ target: T,
//        callbackQueue: DispatchQueue? = nil,
//        progress: Moya.ProgressBlock? = nil,
//        success: @escaping (Json) -> Void,
//        failure: @escaping (ResponseError) -> Void) -> Cancellable {
//        return ApiManager.default.request(
//            target,
//            callbackQueue: callbackQueue,
//            progress: progress,
//            success: success,
//            failure: failure
//        )
//    }
    
    @discardableResult
    func request(
        _ target: T,
        callbackQueue: DispatchQueue? = nil,
        progress: Moya.ProgressBlock? = nil,
        success: @escaping (Json) -> Void,
        failure: @escaping (ResponseError) -> Void) -> Cancellable {
        
        return provider.request(target, callbackQueue: callbackQueue, progress: progress, completion: { [weak self] result in
            guard let `self` = self else {
                failure(ResponseError(message: "api manager has been destoryed", code: .unknow))
                return
            }
            switch result {
            case .success(let response):
                let (response, error) = APIService.handle(moyaResponse: response)
                if let error = error {
                    failure(error)
                }
                else {
                    success(response!)
                }
            case .failure(let error):
                failure(APIService.transform(moyaError: error).1)
            }
            
        })
    }
    
    @discardableResult
    func request(
        _ target: T,
        callbackQueue: DispatchQueue? = nil,
        progress: Moya.ProgressBlock? = nil,
        successWithRawData: @escaping (Data) -> Void,
        failure: @escaping (ResponseError) -> Void) -> Cancellable {
        
        return provider.request(target, callbackQueue: callbackQueue, progress: progress, completion: { [weak self] result in
            guard let `self` = self else {
                failure(ResponseError(message: "api manager has been destoryed", code: .unknow))
                return
            }
            switch result {
            case .success(let response):
                successWithRawData(response.data)
            case .failure(let error):
                failure(APIService.transform(moyaError: error).1)
            }
            
        })
    }
    /// send synchronous request
    /// do not use on Main queue
    ///
    /// - Parameters:
    ///   - target: api target
    ///   - callbackQueue: callback queue
    ///   - progress: progress block
    /// - Returns: response and error
    func sendSynchronousRequest(_ target: T,
                                callbackQueue: DispatchQueue? = nil,
                                progress: Moya.ProgressBlock? = nil) -> (Json?, ResponseError?) {
        let semaphore = DispatchSemaphore(value: 0)
        var response: (Json?, ResponseError?) = (nil, nil)
        request(target, callbackQueue: callbackQueue, progress: progress, success: { json in
            response = (json, nil)
            semaphore.signal()
        }, failure: { error in
            response = (nil, error)
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: .distantFuture)
        return response
    }
}

extension APIService {
    static func handle(moyaResponse response: Moya.Response) -> (Json?, ResponseError?) {
        guard let json = try? Json(response.data) else {
            return (nil, ResponseError(message: "Can't parse respose", code: .parseResponseError) )
        }
        return (json, nil)
    }
    
    static func transform(moyaError error: MoyaError) -> (Json?, ResponseError) {
        return (nil, ResponseError(message: error.localizedDescription, code: .unknow))
    }
}

