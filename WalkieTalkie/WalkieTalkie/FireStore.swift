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
        static let channels = "channels"
//        static let default_channels = "default_channels"
    }
//
    static let shared = FireStore()
    
    static let defaultRoom = Room(name: "WELCOME", user_count: 0)
    
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
            let ref = self?.db.collection(Root.channels)
                .addSnapshotListener(includeMetadataChanges: true, listener: { (query, error) in
                    if let error = error {
                        cdPrint("FireStore Error new: \(error)")
                        observer.onNext([])
                        return
                    } else {
                        guard let query = query else {
                            observer.onNext([])
                            return
                        }
                        let list = query.toRoomList()
                        observer.onNext(list)
                    }
                })
            
            return Disposables.create {
                ref?.remove()
            }
        })
        .startWith([FireStore.defaultRoom])
    }
    
//    func hotChannelList() -> Observable<[Room]> {
//        return Observable<[Room]>.create({ [weak self] (observer) -> Disposable in
//            let ref = self?.db.collection(Root.default_channels)
//                .addSnapshotListener(includeMetadataChanges: true, listener: { (query, error) in
//                    if let error = error {
//                        cdPrint("FireStore Error new: \(error)")
//                        observer.onNext([])
//                        return
//                    } else {
//                        guard let query = query else {
//                            observer.onNext([])
//                            return
//                        }
//                        let list = query.toRoomList()
//                        observer.onNext(list)
//                    }
//                })
//
//            return Disposables.create {
//                ref?.remove()
//            }
//        })
//        .startWith([FireStore.defaultRoom])
//    }
}

extension QuerySnapshot {
    func toRoomList() -> [Room] {
        return documents.map { snapshot -> Room? in
            //            print("snapshot: \(snapshot.documentID) \(snapshot.data())")
            let count = snapshot.data()["user_count"] as? Int ?? 0
            return Room(name: snapshot.documentID, user_count: count)
        }
        .compactMap { $0 }
    }
}

