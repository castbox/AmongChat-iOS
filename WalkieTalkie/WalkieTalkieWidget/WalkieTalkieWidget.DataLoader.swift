//
//  DataLoader.swift
//  WalkieTalkieWidgetExtension
//
//  Created by mayue on 2020/9/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import ObjectMapper

struct DataLoader {
    
    static func fetchTopChannels(completion: @escaping (Result<[Network.Entity.Channel], Error>) -> Void) {
        let _ = Network.Request.fetchTopChannels()
            .subscribe { (channels) in
                completion(.success(channels))
            } onError: { (error) in
                completion(.failure(error))
            }
    }
    
}
