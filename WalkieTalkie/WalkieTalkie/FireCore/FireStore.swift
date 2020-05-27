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
        static let secrets = "secrets"
        static let settings = "settings"
        static let channelConfig = "channel_config"
        //        static let default_channels = "default_channels"
    }
    //
    static let shared = FireStore()
    
    static let defaultRoom = Room(name: "WELCOME", user_count: 0)
    
    let secretChannelsSubject = BehaviorRelay<[Room]>(value: [])
    var secretChannels: [Room] {
        return secretChannelsSubject.value
    }
    
    let publicChannelsSubject = BehaviorRelay<[Room]>(value: [])
    var publicChannels: [Room] {
        return publicChannelsSubject.value
    }
    
    let channelConfigSubject = BehaviorRelay<ChannelConfig>(value: .default)
    static var channelConfig: ChannelConfig {
        return shared.channelConfigSubject.value
    }
    
    lazy var db: Firestore = {
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
        return db
    }()
    
//    private (set) var isInReview: Bool = true
    let isInReviewSubject = BehaviorRelay<Bool>(value: true)

    init() {
        #if DEBUG
        //        Firestore.enableLogging(true)
        #endif
        
        getAppConfigValue()
        
        _ = secretChannelList()
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .catchErrorJustReturn([])
            .bind(to: secretChannelsSubject)
        
        _ = onlineChannelList()
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .catchErrorJustReturn([])
            .bind(to: publicChannelsSubject)
        //static let channelConfig = "channel_config"
        
        #if DEBUG
        _ = channelConfigObservalbe()
            .catchErrorJustReturn(.default)
            .bind(to: channelConfigSubject)
        #else
        _ = channelConfigObservalbe()
            .catchErrorJustReturn(.default)
            .bind(to: channelConfigSubject)
        #endif
    }
    
    func getAppConfigValue() {
        db.collection(Root.settings)
            .document("app_config")
            .getDocument(completion: { [weak self] query, error in
                if let error = error {
                    cdPrint("FireStore Error new: \(error)")
                    //                    observer.onNext(.default)
                    return
                } else {
                    guard let query = query, let data = query.data() else {
                        //                        observer.onNext(.default)
                        return
                    }
                    var config: AppConfig?
                    decoderCatcher {
                        config = try JSONDecoder().decodeAnyData(FireStore.AppConfig.self, from: data)
                    }
                    //                    observer.onNext(config ?? .default)
                    //                    observer.onCompleted()
                    //                    self.
                    self?.isInReviewSubject.accept(config?.reviewVersion == Config.appVersion)
                }
            })
    }
    
    func findValidRoom(with name: String, defaultUserCount: Int = 1) -> Room {
        var room: Room?
        if name.isPrivate {
            room = FireStore.shared.secretChannels.first(where: { $0.name == name })
        } else {
            room = FireStore.shared.publicChannels.first(where: { $0.name == name })
        }
        return room ?? Room(name: name, user_count: defaultUserCount)
    }
    
    func isValidSecretChannel(_ name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        return FireStore.shared.secretChannels.contains(where: { $0.name == name }) //则检查是否存在
    }
    
    func checkIsValidSecretChannel(_ name: String?, completionHandler: @escaping (Bool) -> Void) {
        db.collection(Root.secrets)
            .getDocuments(source: .server, completion: { (query, error) in
                if let error = error {
                    cdPrint("FireStore Error new: \(error)")
                    completionHandler(false)
                    return
                } else {
                    guard let query = query else {
                        completionHandler(false)
                        return
                    }
                    let result = query.toRoomList().contains(where: { $0.name == name })
                    completionHandler(result)
                }
            })
        
    }
    
    func channelConfigObservalbe() -> Observable<FireStore.ChannelConfig> {
        return Observable<FireStore.ChannelConfig>.create({ [weak self] (observer) -> Disposable in
            self?.db.collection(Root.settings)
                .document("channel_config")
                .getDocument(completion: { query, error in
                    if let error = error {
                        cdPrint("FireStore Error new: \(error)")
                        observer.onNext(.default)
                        return
                    } else {
                        guard let query = query, let data = query.data() else {
                            observer.onNext(.default)
                            return
                        }
                        var config: ChannelConfig?
                        decoderCatcher {
                            config = try JSONDecoder().decodeAnyData(FireStore.ChannelConfig.self, from: data)
                        }
                        observer.onNext(config ?? .default)
                        observer.onCompleted()
                    }
                })
            return Disposables.create {
            }
        })
    }
    
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
    
    func secretChannelList() -> Observable<[Room]> {
        return Observable<[Room]>.create({ [weak self] (observer) -> Disposable in
            let ref = self?.db.collection(Root.secrets)
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
        .startWith([])
    }
}

extension QuerySnapshot {
    func toRoomList() -> [Room] {
        return documents.map { snapshot -> Room? in
            let count = snapshot.data()["user_count"] as? Int ?? 0
            let persistence = snapshot.data()["persistence"] as? Bool ?? false
            return Room(name: snapshot.documentID, user_count: count, persistence: persistence)
        }
        .compactMap { $0 }
    }
}

