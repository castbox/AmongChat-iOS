//
//  FireStore.swift
//  Cuddle
//
//  Created by Marry on 2019/7/3.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseCore
//import SwiftyJSON
import RxSwift
import RxCocoa

class FireStore {
    
    /// 根结点名称
    struct Root {
        static let stat = "stat"
        static let channel = "channel"
    }
//
    static let shared = FireStore()
    
    lazy var db: Firestore = {
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
        return db
    }()

//    init() {
//        if let token = Knife.Auth.shared.loginResult.value?.firebase_custom_token {
//            Auth.auth().signIn(withCustomToken: token) { (user, error) in
//                if let error = error {
//                    cdPrint("fire store auth error: \(error)")
//                } else {
//                    if let user = user {
//                        cdPrint("auth user: \(user)")
//                    }
//                }
//            }
//        }
//        // bag map [pid: BagProducts]
//        createMaps()
//        // activity map [aid: Activity]
//        createActivityMap()
//
//        #if DEBUG
////        Firestore.enableLogging(true)
//        #endif
//    }
//
    
    func onlineChannelList() -> Observable<[Room]> {
        return Observable<[Room]>.create({ [weak self] (observer) -> Disposable in
            
            let ref = self?.db.collection(Root.stat)
                .document("channel_info")
                .addSnapshotListener(includeMetadataChanges: true, listener: { (query, error) in
                    if let error = error {
                        cdPrint("FireStore Error new: \(error)")
                        observer.onNext([])
                        return
                    } else {
                        guard let query = query,
                            let data = query.data(),
                            let channels = data["channels"] as? [[String: Any]] else {
                                observer.onNext([])
                                return
                        }
                        //                    let data = query.documents.map { $0.data() }
                        var list: [Room] = []
                        decoderCatcher {
                            list = try JSONDecoder().decodeAnyData([Room].self, from: channels)
                        }
//                        completion(list)
                        observer.onNext(list)
                    }
                })
            
            return Disposables.create {
                ref?.remove()
            }
        })
    }
    
    func hotChannelList() -> Observable<[Room]> {
        return Observable<[Room]>.create({ [weak self] (observer) -> Disposable in
            
            let ref = self?.db.collection(Root.channel)
                .document("default")
                .addSnapshotListener(includeMetadataChanges: true, listener: { (query, error) in
                    if let error = error {
                        cdPrint("FireStore Error new: \(error)")
                        observer.onNext([])
                        return
                    } else {
                        guard let query = query,
                            let data = query.data(),
                            let channels = data["hot"] as? [[String: Any]] else {
                                observer.onNext([])
                                return
                        }
                        var list: [Room] = []
                        decoderCatcher {
                            list = try JSONDecoder().decodeAnyData([Room].self, from: channels)
                        }
                        //                        completion(list)
                        observer.onNext(list)
                    }
                })
            
            return Disposables.create {
                ref?.remove()
            }
        })
    }

}

