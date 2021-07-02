//
//  Routes.swift
//  Castbox
//
//  Created by ChenDong on 2017/11/24.
//  Copyright © 2017年 Guru. All rights reserved.
//

import Foundation
import JLRoutes
import RxSwift

final class Routes {
    
    static let shared = Routes()
    private let uriSubject = PublishSubject<URIRepresentable>()
    func uriValue() -> Observable<URIRepresentable> {
        return uriSubject
    }
    
    private init() {
        
        let routes = JLRoutes.global()
        let subject = uriSubject
        
        let types: [URIRepresentable.Type] = [
            URI.Homepage.self,
            URI.Followers.self,
            URI.Channel.self,
            URI.CreateRoom.self,
            URI.Profile.self,
            URI.Search.self,
            URI.Avatars.self,
            URI.InviteUser.self,
            URI.FansGroup.self,
            URI.AllNotice.self,
            URI.DMMessage.self,
            URI.ProfileFeeds.self,
            URI.DMInteractiveMessage.self,
            URI.Feeds.self,
            URI.GroupJoinRequests.self
            ]
        
        types.forEach { (type) in
            routes.addRoutes(type.patterns()) { paras in
                guard let instance = type.init(paras) else { return false }
                subject.onNext(instance)
                return true
            }
        }
        
        routes.unmatchedURLHandler = { routes, url, paras in
            guard let url = url else { return }
            subject.onNext(URI.Undefined(url))
        }
    }
    
    @discardableResult
    static func handle(_ url: URL?)->Bool {
        guard let url = url else { return false }
        _ = Routes.shared
        return JLRoutes.global().routeURL(url)
    }
    
    @discardableResult
    static func handle(_ uri: String?) -> Bool {
        guard var str = uri else { return false }
        if str.hasPrefix("http") == false {
            if !str.hasPrefix("/") {
                str = "/" + str
            }
            str = "https://among.chat" + str
        }
        guard let url = str.robustURL else { return false }
        _ = Routes.shared
        if url.host == "among.chat" {
            return JLRoutes.global().routeURL(url)
        } else {
            Routes.shared.uriSubject.onNext(URI.Undefined(url))
            return true
        }
    }
    
    @discardableResult
    static func handle(_ uri: String?, extraWork: @escaping (URIRepresentable) -> Void) -> Bool {
        _ = Routes.shared.uriValue()
            .take(1)
            .subscribe { (event) in
            if let elem = event.element {
                extraWork(elem)
            }
        }
        return handle(uri)
    }

    static func canHandle(_ url: URL)->Bool {
        guard url.host == "www.walkietalkie.live" || url.host == "walkietalkie.live" || url.host == "among.chat" else { return false }
        _ = Routes.shared
        return JLRoutes.global().canRouteURL(url)
    }
}
