//
//  ApiManagerPlugin.swift
//  Moya-Cuddle
//
//  Created by Wilson on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Moya
import Alamofire

extension ApiManager {
    class RequestHandlingPlugin: PluginType {

        /// Called to modify a request before sending
        public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
            var mutateableRequest = request
            return mutateableRequest.appendCommonParams()
        }

        /// Called after a response has been received, but before the MoyaProvider has invoked its completion handler.
        func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
            var httpResponse: Json?
            var responseError: ResponseError?

            switch result {
            case .success(let response):
                (httpResponse, responseError) = APIService.handle(moyaResponse: response)
            case .failure(let error):
                let result = APIService.transform(moyaError: error)
                httpResponse = result.0
                responseError = result.1
            }

            APIService.ErrorHandle.handle(httpResponse: httpResponse, error: responseError)
        }
    }
}

extension URLRequest {
    
    /// global common params
    private var commonParams: [String: Any] {
        return APIService.Config.commonQueryParams
    }
    
    /// global common header fields
    private var commonHeaderFields: [String: String] {
        return [:]
    }
    
    mutating func appendCommonParams() -> URLRequest {
        allHTTPHeaderFields = HTTPHeaders.default.dictionary
        let newHeaderFields = (allHTTPHeaderFields ?? [:]).merging(commonHeaderFields) { current, _ in current }
        allHTTPHeaderFields = newHeaderFields
        let request = try? encoded(parameters: commonParams, parameterEncoding: URLEncoding(destination: .queryString))
        assert(request != nil, "append common params failed, please check common params value")
        return request!
    }
    
    func encoded(parameters: [String: Any], parameterEncoding: ParameterEncoding) throws -> URLRequest {
        do {
            return try parameterEncoding.encode(self, with: parameters)
        } catch {
            throw MoyaError.parameterEncoding(error)
        }
    }
}

