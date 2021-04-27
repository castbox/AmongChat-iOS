//
//  NewsManager.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

class NewsManager {
    
    static let shared = NewsManager()
    
    private let dbIOQueue = DispatchQueue.init(label: "among.chat.news.db.io", qos: .userInitiated)
    
    private let dbPath: URL = {
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask,
                                                         true).last! + "/LocalData/News.db"
        return URL(fileURLWithPath: dbPath)
    }()

    private let db: DB.DBManager
    
    private init() {
        db = DB.DBManager(dbPath)
        
    }
    
}
