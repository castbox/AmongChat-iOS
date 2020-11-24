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
import SwifterSwift
import FirebaseAuth
import SwiftyUserDefaults

class FireStore {
    
    /// 根结点名称
    struct Root {
        static let secrets = "secrets"
        static let settings = "settings"
        static let channelConfig = "channel_config"
        //        static let default_channels = "default_channels"
        static let channels = "channels"
        static let users = "users"
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
    let appConfigSubject = BehaviorRelay<AppConfig?>(value: nil)
    let isInReviewSubject = BehaviorRelay<Bool>(value: true)
    
    private let firebaseSignedInSubject = ReplaySubject<Void>.create(bufferSize: 1)
    
    var firebaseSignedInObservable: Observable<Void> {
        return firebaseSignedInSubject.asObservable()
    }

    init() {
        #if DEBUG
        //        Firestore.enableLogging(true)
        #endif
        
        let _ = firebaseSignedInSubject.take(1)
            .subscribe(onNext: { [weak self] (_) in
                
                guard let `self` = self else { return }
                
                self.getAppConfigValue()

                let _ = Observable<Int>.interval(.seconds(60), scheduler: MainScheduler.instance)
                    .startWith(0)
                    .subscribe(onNext: { (_) in
                        
                        let _ = self.fetchOnlineChannelList()
                            .catchErrorJustReturn([])
                            .observeOn(SerialDispatchQueueScheduler(qos: .default))
                            .subscribe(onSuccess: { (rooms) in
                                self.publicChannelsSubject.accept(rooms)
                                SharedDefaults[\.topPublicChannelsKey] = rooms.sorted(by: { (left, right) -> Bool in
                                    left.user_count > right.user_count
                                }).map({ (room) -> [String : Any] in
                                    return ["name" : room.name, "userCount" : room.user_count]
                                })
                                .first(2)
                            })
                        
                        let _ = self.fetchSecretChannelList(of: Defaults[\.secretChannels].map({ $0.name }))
                            .observeOn(SerialDispatchQueueScheduler(qos: .default))
                            .catchErrorJustReturn([])
                            .subscribe(onSuccess: { (rooms) in
                                self.secretChannelsSubject.accept(rooms)
                            })
                    })
                
                #if DEBUG
                _ = self.channelConfigObservalbe()
                    .catchErrorJustReturn(.default)
                    .bind(to: self.channelConfigSubject)
                #else
                _ = self.channelConfigObservalbe()
                    .catchErrorJustReturn(.default)
                    .bind(to: self.channelConfigSubject)
                #endif
            })
        
        let _ = Settings.shared.loginResult.replay()
            .filterNil()
            .subscribe(onNext: { [weak self] (result) in
                self?.signIn(with: result.firebaseToken)
            })
    }
    
    private func signIn(with token: String) {
        
        Auth.auth().signIn(withCustomToken: token) { [weak self] (user, error) in
            if let error = error {
                cdPrint("fire store auth error: \(error)")
            } else {
                self?.firebaseSignedInSubject.onNext(())
            }
        }
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
                    self?.appConfigSubject.accept(config)
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
                .document(Root.channelConfig)
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
    
    private func onlineChannelList() -> Observable<[Room]> {
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
    
    private func fetchOnlineChannelList() -> Single<[Room]> {
        return Observable<[Room]>.create({ [weak self] (observer) -> Disposable in
            self?.db.collection(Root.channels)
                .getDocuments(completion: { (query, error) in
                    if let error = error {
                        cdPrint("FireStore Error new: \(error)")
                        observer.onError(error)
                        return
                    } else {
                        guard let query = query else {
                            observer.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                            return
                        }
                        let list = query.toRoomList()
                        observer.onNext(list)
                        observer.onCompleted()
                    }
                })
            
            return Disposables.create { }
        })
            .asSingle()
    }
    
    private func fetchSecretChannelList(of channelIds: [String]) -> Single<[Room]> {
        return Observable<[Room]>.create({ [weak self] (observer) -> Disposable in
            
            guard let `self` = self,
                channelIds.count > 0 else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create { }
            }
            
            let idsChunk = channelIds.chunked(into: 10)
            
            let obs = idsChunk.map { self._fetchSecretChannelList(of: $0).catchErrorJustReturn([]) }
            
            let d = Observable.from(obs)
                .flatMap { $0 }
                .subscribe(onNext: { (rooms) in
                    observer.onNext(rooms)
                    observer.onCompleted()
                }, onError: { (error) in
                    observer.onError(error)
                })
            
            return Disposables.create {
                d.dispose()
            }
        })
            .asSingle()
    }
    
    private func _fetchSecretChannelList(of channelIds: [String]) -> Single<[Room]> {
        return Observable<[Room]>.create({ [weak self] (observer) -> Disposable in
            
            guard channelIds.count > 0 else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create { }
            }
            
            self?.db.collection(Root.secrets)
                .whereField(FieldPath.documentID(), in: channelIds)
                .getDocuments(completion: { (query, error) in
                    if let error = error {
                        cdPrint("FireStore Error new: \(error)")
                        observer.onError(error)
                        return
                    } else {
                        guard let query = query else {
                            observer.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                            return
                        }
                        let list = query.toRoomList()
                        observer.onNext(list)
                        observer.onCompleted()
                    }
                })
            
            return Disposables.create { }
        })
            .asSingle()
    }
    
    private func secretChannelList() -> Observable<[Room]> {
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
    
    func update(emoji: [String], for channel: String, completionHandler: ((Bool) -> Void)? = nil) -> String {
        let updated = String(Date().timeIntervalSince1970).hashed(.md5) ?? ""
        let data: [String: Any] = ["emoji": [
            "chars": emoji,
            "updated": updated, ]
        ]
        
        if !channel.isPrivate {
            guard publicChannels.contains(where: { $0.name == channel }) else {
                completionHandler?(false)
                return updated
            }
            //检查是否存在
            db.collection(Root.channels)
                .document(channel)
                .setData(data, merge: true, completion: { (error) in
                    if let error = error {
                        cdPrint("failed: \(error)")
                        completionHandler?(false)
                    } else {
                        cdPrint("success")
                        completionHandler?(true)
                    }
                })
            
        } else {
            guard secretChannels.contains(where: { $0.name == channel }) else {
                completionHandler?(false)
                return updated
            }
            //检查是否存在
            db.collection(Root.secrets)
                .document(channel)
                .setData(data, merge: true, completion: { (error) in
                    if let error = error {
                        cdPrint("failed: \(error)")
                        completionHandler?(false)
                    } else {
                        cdPrint("success")
                        completionHandler?(true)
                    }
                })
        }
        return updated
    }
    
    func observerEmoji(at channel: String) -> Observable<Room?> {
        return Observable<Room?>.create({ [weak self] (observer) -> Disposable in
            var documentRef: DocumentReference? {
                if channel.isPrivate {
                    return self?.db.collection(Root.secrets)
                        .document(channel)
                }  else {
                    return self?.db.collection(Root.channels)
                        .document(channel)
                }
            }
            let ref = documentRef?
                .addSnapshotListener({ snapshot, error in
                    if let error = error {
                        cdPrint("FireStore Error new: \(error)")
                        //                        observer.onNext()
                        return
                    } else {
                        guard let data = snapshot?.toRoom() else {
                            //                            observer.onNext([])
                            return
                        }
                        observer.onNext(data)
                    }
                })
            return Disposables.create {
                ref?.remove()
            }
        })
    }
    
    func fetchSecretChannel(of channel: String) -> Single<Room?> {
        
        return Observable<Room?>.create { [weak self] (subscriber) -> Disposable in
            self?.db.collection(Root.secrets)
                .document(channel)
                .getDocument(completion: { (doc, error) in
                    if let error = error {
                        subscriber.onError(error)
                    } else {
                        let room = doc?.toRoom()
                        subscriber.onNext(room)
                        subscriber.onCompleted()
                        
                        if let room = room,
                            let `self` = self {
                            var secretRooms = self.secretChannelsSubject.value
                            if let idx = secretRooms.firstIndex(where: { $0.name == room.name }) {
                                secretRooms[idx] = room
                            } else {
                                secretRooms.append(room)
                            }
                            self.secretChannelsSubject.accept(secretRooms)
                        }
                    }
                })
            
            return Disposables.create { }
        }
        .asSingle()
        
    }
    
    func channelObservable(of channel: String) -> Observable<Room?> {
        let root: String
        
        if channel.isPrivate {
            root = Root.secrets
        } else {
            root = Root.channels
        }
        return _channelObservable(of: channel, root: root)
    }
    
    private func _channelObservable(of channel: String, root: String) -> Observable<Room?> {
        
        return Observable<Room?>.create { [weak self] (subscriber) -> Disposable in
            
            let ref = self?.db.collection(root)
                .document(channel)
                .addSnapshotListener({ (doc, error) in
                    guard error == nil else {
                        subscriber.onError(error!)
                        return
                    }
                    
                    guard let doc = doc else {
                        subscriber.onError(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Error fetching snapshots"]))
                        return
                    }
                    
                    subscriber.onNext(doc.toRoom())
                })
            
            return Disposables.create {
                ref?.remove()
            }
        }
        
    }
    
}

extension QuerySnapshot {
    func toRoomList() -> [Room] {
        return documents
            .map { $0.toRoom() }
            .compactMap { $0 }
    }
}

extension DocumentSnapshot {
    func toRoom() -> Room? {
        guard let data = data() else {
            return nil
        }
        let count = data["user_count"] as? Int ?? 0
        let persistence = data["persistence"] as? Bool ?? false
        var emoji: Room.Emoji?
        if let emojiData = data["emoji"] as? [String: Any] {
            emoji = try? JSONDecoder().decodeAnyData(Room.Emoji.self, from: emojiData)
        }
        
        let userList: [UInt] = data["user_list"] as? [UInt] ?? []
        var room = Room(name: documentID, user_count: count, persistence: persistence, emoji: emoji)
        room.user_list = userList
        return room
    }
}

