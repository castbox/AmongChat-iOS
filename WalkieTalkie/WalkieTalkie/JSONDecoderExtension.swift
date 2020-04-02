//
//  JSONDecoderExtension.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/2/7.
//  Copyright © 2020 Guru. All rights reserved.
//

import Foundation

extension JSONDecoder {
    func decodeAnyData<T>(_ type: T.Type, from data: Any) throws -> T where T: Decodable {
        var unwrappedData = Data()
        if let data = data as? Data {
            unwrappedData = data
        }
        else if let data = data as? [String: Any] {
            unwrappedData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        }
        else if let data = data as? [[String: Any]] {
            unwrappedData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        }
        else {
            fatalError("error format of data ")
        }
        return try decode(type, from: unwrappedData)
    }
}
