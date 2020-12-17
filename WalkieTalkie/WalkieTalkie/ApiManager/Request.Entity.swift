//
//  Request.Entity.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension Request {
    struct Entity { }
}

extension Request.Entity {
    
    public enum LoginProvider: String {
        case google
        case apple
    }
}

extension Request.Entity {
    
    struct LoginResult: Codable {
        
        var uid: Int
        var access_token: String
        var provider: String

        var source: String?
        
        // will be deprecated soon
        var firebase_custom_token: String
        //
        
        var picture_url: String?
        var name: String?
        var is_login: Bool?
        var is_new_user: Bool?
        var new_guide: Bool?
        
        var create_time : Int64?
        
//        init?(with dict: [String : Any]) {
//            guard  let uid = dict["uid"] as? Int,
//                   let provider = dict["provider"] as? String,
//                   let access_token = dict["access_token"] as? String else {
//                return nil
//            }
//
//            self.uid = uid
//            self.provider = provider
//            self.access_token = access_token
//
//            source = dict["source"]
//
//            // will be deprecated soon
//            firebase_custom_token = dict["firebase_custom_token"]
//            //
//
//            picture_url = dict[""]
//            name = dict[""]
//            is_login =
//            var is_new_user: Bool?
//            var new_guide: Bool?
//
//            var create_time : Int64
//
//        }
        
    }
}
