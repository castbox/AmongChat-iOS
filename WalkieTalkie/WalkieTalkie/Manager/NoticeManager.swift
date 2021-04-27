//
//  NoticeManager.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

class NoticeManager {
    
    static let shared = NoticeManager()
    
    private let dbIOQueue = DispatchQueue.init(label: "among.chat.notice.db.io", qos: .userInitiated)
    
    private let dbPath: URL = {
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                         .userDomainMask,
                                                         true).last! + "/Notice/Notice.db"
        return URL(fileURLWithPath: dbPath)
    }()

    private let db: DB.DBManager
    
    private init() {
        db = DB.DBManager(dbPath)
        
    }
    
}
