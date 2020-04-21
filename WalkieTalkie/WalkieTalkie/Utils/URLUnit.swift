//
//  URLUnit.swift
//  Castbox
//
//  Created by ChenDong on 2018/9/27.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit

/// 处理 URL 的单元，将字符串转化为 URL
final class URLUnit {
    
    let string: String
    
    init(string: String) {
        self.string = string
    }
    
    /**
     转换为 URL，可能为 nil
     */
    private(set) lazy var url: URL? = {
        
        // 从 SwiftyJSON 那里偷来的
        if string.isEmpty {
            return nil
        }
        
        // Check for existing percent escapes first to prevent double-escaping of % character
        if let _ = string.range(of: "%[0-9A-Fa-f]{2}", options: .regularExpression, range: nil, locale: nil) {
            return URL(string: string)
            
        } else if let encodedString_ = string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            // We have to use `Foundation.URL` otherwise it conflicts with the variable name.
            return URL(string: encodedString_)
            
        } else {
            return nil
        }
    }()
}

extension String {
    var robustURL: URL? {
        return URLUnit(string: self).url
    }
    
//    func firstCharacterUpperCase() -> String? {
//         guard !isEmpty else { return nil }
//         let lowerCasedString = self.lowercased()
//         return lowerCasedString.replacingCharacters(in: lowerCasedString.startIndex...lowerCasedString.startIndex, with: String(lowerCasedString[lowerCasedString.startIndex]).uppercased())
//     }
}


extension URL {
    func addQueryParams(newParams: [URLQueryItem]) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        if (urlComponents.queryItems == nil) {
            urlComponents.queryItems = [];
        }
        urlComponents.queryItems?.append(contentsOf: newParams);
        return urlComponents.url;
    }
}
