//
//  Cuddle.Config.swift
//  Moya-Cuddle
//
//  Created by Wilson on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation

extension APIService {
    struct Config {
        static var isRelease: Bool {
            #if DEBUG
            return false
            #else
            return true
            #endif
        }
        
        static var host: String {
            if isRelease {
                return "https://us-central1-walkietalkie-a6b37.cloudfunctions.net/"
            } else {
                return "https://us-central1-walkietalkie-a6b37.cloudfunctions.net/"
            }
        }
        
        public static var userAgent: String {
            var deviceInfo = Constants.deviceInfo()
            if let loginResult = Settings.shared.loginResult.value {
                deviceInfo["uid"] = loginResult.uid
            }
            
            let uaString = deviceInfo.map({"\($0)=\($1)"}).joined(separator: ";") + ";"
            return uaString
        }

        
        static var commonQueryParams: [String: String] {
            return [:]
        }
        
        static func appenCommonQueryParams(to url: String) -> String? {
            guard var component = URLComponents(string: url) else {
                return nil
            }
            component.queryItems = commonQueryParams
                .map { URLQueryItem(name: $0.key, value: $0.value) }
            return component.url!.absoluteString
        }
    }

}
