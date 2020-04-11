//
//  Json.swift
//  Moya-Cuddle
//
//  Created by Wilson-Yuan on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation

class Json {
    
    enum JsonError: Error {
        case message(String)
    }
    
    private (set) var jsonObj: Any
    
    init(_ object: Any) {
        jsonObj = object
    }
    
    convenience init(_ jsonData: Data) throws {
        let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        self.init(jsonObj)
    }
    
    convenience init(_ jsonString: String) throws {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw JsonError.message("can't get data from giving string")
        }
        try self.init(jsonData)
    }
    
    //////////////////////////////////////////////////////
    func hasValue(forKey key: String) -> Bool {
        guard let dicJson = jsonObj as? [String: Any] else {
            return false
        }
        return dicJson[key] != nil
    }
    
    //////////////////////////////////////////////////////
    func hasValue(at index: Int) -> Bool {
        guard let array = jsonObj as? [Any] else { return false }
        return index < array.count
    }
    
    //////////////////////////////////////////////////////
    /**
     * @return return json raw string
     */
    func stringJson() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    //////////////////////////////////////////////////////
    func description() -> String? {
        guard let descriptable = jsonObj as? CustomStringConvertible else {
            return nil
        }
        return descriptable.description
    }
    
    //////////////////////////////////////////////////////
    /**
     * @return count of
     */
    func count() -> Int {
        guard let array = jsonObj as? [Any] else {
            return 0
        }
        return array.count
    }
    
    //////////////////////////////////////////////////////
    func originValue(forKey key: String) -> Any? {
        guard let dicJson = jsonObj as? [String: Any] else {
            return false
        }
        return dicJson[key]
    }
    
    //////////////////////////////////////////////////////
    func json(forKey key: String) -> Json? {
        guard let value = originValue(forKey: key) else {
            return nil
        }
        if (value is [AnyHashable: Any]) || (value is [Any]) {
            return Json(value)
        }
        return nil
    }
    
    //////////////////////////////////////////////////////
    /**
     * retrieve string value for key
     *
     * @param key
     * @param defaultStr
     */
    func stringValue(forKey key: String, defaultValue defaultStr: String? = nil) -> String? {
        guard let value = originValue(forKey: key) else {
            return defaultStr
        }
        if value is String {
            return value as? String
        } else if value is CustomStringConvertible {
            return (value as? CustomStringConvertible)?.description
        } else {
            return defaultStr
        }
    }
    
    //    //////////////////////////////////////////////////////
    func integerValue(forKey key: String, defaultValue defaultInt: Int = 0) -> Int {
        guard let value = originValue(forKey: key) else {
            return defaultInt
        }
        if let value = value as? String {
            return Int(value) ?? 0
        }
        let nilableIntValue = value as? Int
        return nilableIntValue ?? 0
    }
}
