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
            
            if let info = Bundle.main.infoDictionary {
                let executable = "Cuddle"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown" /// 4.1.2
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown" /// fm.castbox.audiobook.radio.podcast
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown" /// 2
                
                let osNameVersion: String = {
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                    let osName = "iOS"
                    return "\(osName) \(versionString)"
                }() /// iOS 11.2.6
                
                /// CastBox/4.1.2 fm.castbox.audiobook.radio.podcast; build:2; iOS 11.2.6
                return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion))"
            }
            return "CastBox"
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
