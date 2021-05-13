//
//  URI.swift
//  Castbox
//
//  Created by ChenDong on 2018/3/22.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation

/*
 2017年11月23日
 有一个需求，用户点击 https 类型的 URL，如果安装了 app，则进入 app 进行相关的处理，如果没有安装 app，则在网页内进行处理。详细见以下链接
 https://docs.google.com/document/d/1nv7aDEz-BGwWnq3ikai-vcRftFhGWw4ChD7sUrWxgRo/edit
 方案1：URL Scheme。如果使用这种方式，就需要配置形如 castbox 的 scheme，（在 iOS，scheme 配置成 https 无效，且没法声明 host 为 castbox）而这样的话，网页任何想要支持跳转 app 处理的 URL 都需要进行一次跳转前判断。如果安装了 app，则还需要翻译成 castbox scheme。比如，在网页播放一个 channel，URL 为 https://castbox.fm/ch/id12345, 那么对应的 URL scheme 为 castbox://ch/12345。另外，URL Scheme 还有一个缺点，一些 app 内的 webview 拦截了所有 URL Scheme 形式的跳转，比如微信
 方案2：Universal URL。使用这种方式，URL 的跳转前判断就成了 iOS 系统的任务，自己前端不需要任何拦截、判断、转化代码，只需要配置 https://castbox.fm/apple-app-site-association 即可。另外，因为 Universal URL 是系统层级的拦截，所以其它 app 就无法拦截了
 
 最终采取方案2
 */


// 采用 Universal URL 技术 https://developer.apple.com/library/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html
// 1. 修改 apple-app-site-association：https://github.com/castbox/castbox-site
// 2. 部署文件： ssh ec2-user@52.197.90.119
//             sh ~/ty/bin/deploy-site.sh
// 3. 测试地址：http://webapp.castbox.fm/app/castbox/static/views/testdeeplink.html
//
protocol URIRepresentable {
    static func patterns() -> [String]
    init?(_ paras: [String: Any])
}

struct URI {}
/// 2.4 开始支持 URI
/*
 routes.addRoute("/epl/:eplID") { (paras) -> Bool in
 return true
 }
 
 routes.addRoute("/premium") { (paras) -> Bool in
 return true
 }
 
 routes.addRoute("/ch/:cid/premium") { (paras) -> Bool in
 return true
 }
 
 routes.addRoute("/premium") { (paras) -> Bool in
 return true
 }*/

extension URI {
    
    struct Homepage: URIRepresentable {
        
        static func patterns() -> [String] {
            return [
                "/",
            ]
        }
        
        let channelName: String?
        
        init?(_ paras: [String: Any]) {
            if let channel = paras["channel"] as? String {
                channelName = channel
            } else if let channel = paras["passcode"] as? String {
                channelName = "_\(channel)"
            } else {
                channelName = nil
            }
        }
    }
    
    struct Profile: URIRepresentable {
        
        static func patterns() -> [String] {
            return [
                "/profile/:uid",
                "/profile"
            ]
        }
        
        let uid: Int?
        
        init?(_ paras: [String: Any]) {
            self.uid = Int(paras["uid"] as? String ?? "")
        }
        
    }
    
    //回流信息
    struct InviteUser: URIRepresentable {
        //https://among.chat/user?uid=xxx&sign=xxxxx
        static func patterns() -> [String] {
            return [
                "/user/:uid",
                "/user"
            ]
        }
        
        let uid: String?
        
        init?(_ paras: [String: Any]) {
            self.uid = paras["uid"] as? String
        }
        
    }
    
    struct CreateRoom: URIRepresentable {
        
        static func patterns() -> [String] {
            return [
                "/createRoom"
            ]
        }
        
        init?(_ paras: [String: Any]) {
        }
    }
    
    struct Channel: URIRepresentable {
        
        static func patterns() -> [String] {
            return [
                "/room/:room_id",
                "/room",
                "/channel/:channel_id",
                "/channel",
            ]
        }
        
        let channelId: String
        let sourceType: String?
        
        init?(_ paras: [String : Any]) {
            var roomId: String?
            if let channelId = paras["room_id"] as? String {
                roomId = channelId
            }
            if roomId == nil, let channelId = paras["channel_id"] as? String {
                roomId = channelId
            }
            guard let channelId = roomId else { return nil }
            self.channelId = channelId
            sourceType = paras["push_source_type"] as? String
        }
        
    }
    
    struct Followers: URIRepresentable {
        static func patterns() -> [String] {
            return [
                "/follower",
                "/followers"
            ]
        }
        
        init?(_ paras: [String : Any]) {
        }
    }
    
    struct Search: URIRepresentable {
        static func patterns() -> [String] {
            return [
                "/search"
            ]
        }
        
        init?(_ paras: [String : Any]) {
        }
    }
    
    struct Avatars: URIRepresentable {
        static func patterns() -> [String] {
            return [
                "/avatars"
            ]
        }
        
        init?(_ paras: [String : Any]) {
        }
    }
    
    struct FansGroup: URIRepresentable {
        
        static func patterns() -> [String] {
            return [
                "/group/:gid",
                "/group"
            ]
        }
        let groupId: String
        
        init?(_ paras: [String : Any]) {
            
            guard let gid = paras["gid"] as? String else { return nil }
            
            groupId = gid
        }
        
    }
    
    struct DMMessage: URIRepresentable {
        
        static func patterns() -> [String] {
            return [
                "/message/:uid",
                "/message"
            ]
        }
        let uid: String
        
        init?(_ paras: [String : Any]) {
            
            guard let uid = paras["uid"] as? String else { return nil }
            
            self.uid = uid
        }
        
    }
    
    struct AllNotice: URIRepresentable {
        static func patterns() -> [String] {
            return [
                "/allNotice",
            ]
        }
        
        init?(_ paras: [String : Any]) {
        }
    }
    
    struct Undefined: URIRepresentable {
        
        static func patterns() -> [String] {
            return []
        }
        
        let url: URL
        init(_ url: URL) {
            self.url = url
        }
        
        init?(_ paras: [String: Any]) {
            return nil
        }
    }
}
