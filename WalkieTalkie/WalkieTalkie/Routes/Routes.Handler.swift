//
//  Routes.Handler.swift
//  Castbox
//
//  Created by ChenDong on 2018/1/16.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation

//import FBSDKCoreKit
//import GoogleSignIn
//import TwitterKit
//import FirebaseAnalytics
import FirebaseDynamicLinks

import RxSwift

extension Routes {
    
    final class Handler {
        
        static let shared = Handler()
        
        private let bag = DisposeBag()
        
        private init() {
            weak var welf = self
            //
            Routes.shared.uriValue()
                .flatMap { item -> Observable<URIRepresentable> in
                    return Observable.just(item)
                        .delay(.fromSeconds(0.5), scheduler: MainScheduler.asyncInstance)
                }
                .subscribe(onNext: { (uri) in
                    guard let `self` = welf else { return }
                    switch uri {
                    case let home as URI.Homepage:
                        self.handleHomepage(home.channelName)
                    case let undefined as URI.Undefined:
                        self.handleUndefined(undefined.url)
                        
                    default:
                        cdAssertFailure("should never enter here")
                    }
                })
                .disposed(by: bag)
        }
        
        func handleHomepage(_ channelName: String?) {
            guard let name = channelName,
                let roomVc = UIApplication.navigationController?.viewControllers.first as? RoomViewController else {
                return
            }
            
            roomVc.joinChannel(name)
        }
        
        func showWebViewController(urlString: String) {
            guard let url = URL(string: urlString),
            let controller = UIApplication.navigationController?.topViewController else { return }
            controller.open(url: url)
        }
        
        func handleUndefined(_ url: URL) {
            if !FireLink.handle(dynamicLink: url, completion: { (url) in
                Routes.handle(url)
            }) {
                guard !url.absoluteString.contains("cuddlelive.com/share-app") else { return }
                cdPrint("open url on webpage: \(url.absoluteString)")
                showWebViewController(urlString: url.absoluteString)
            }
        }

    }
}
