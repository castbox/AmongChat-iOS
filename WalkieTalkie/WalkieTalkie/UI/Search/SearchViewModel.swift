//
//  SearchViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyUserDefaults

struct Room: Codable, DefaultsSerializable {
    static let `default` = Room(name: "WELCOME", user_count: 0)
    
    let name: String
    let user_count: Int
    var joinAt: TimeInterval
    
    init(name: String,
         user_count: Int,
         joinAt: TimeInterval = Date().timeIntervalSince1970) {
        self.name = name
        self.user_count = user_count
        self.joinAt = joinAt
    }
    
    mutating func updateJoinInterval() {
        joinAt = Date().timeIntervalSince1970
    }
    
    var showName: String {
        return name.showName
    }
    
    var isReachMaxUser: Bool {
        return FireStore.channelConfig.isReachMaxUser(self)
    }
    
    var userCountForShow: String {
        if isReachMaxUser {
            return R.string.localizable.channelUserMax()
        } else {
            return user_count.string
        }
    }
    
    var isPrivate: Bool {
        return name.hasPrefix("_")
    }
    
//    var isValid: Bool {
//        guard isPrivate else {
//            return true
//        }
//        print("joinAt: \(joinAt) valid: \(joinAt - Date().timeIntervalSince1970 < 30 * 60)")
//        return joinAt - Date().timeIntervalSince1970 < 30 * 60 //30 minute
//    }
    
//    private enum CodingKeys: String, CodingKey {
//        case name
//        case user_count
//    }
}

extension String {
    var showName: String {
        if isPrivate {
            guard let name = split(bySeparator: "_").last else {
                return self
            }
            let start = name.index(name.startIndex, offsetBy: 2)
            let end = name.endIndex
            return name.replacingCharacters(in: start ..< end, with: "******")
        } else {
            return self
        }
    }
    
    var publicName: String? {
        return split(bySeparator: "_").last
    }
    
    var isPrivate: Bool {
        return hasPrefix("_")
    }
    
    var channelType: ChannelType {
        return isPrivate ? .private : .public
    }
}

//extension UserDefaults {
//    subscript<T: Codable>(key: DefaultsKey<T?>) -> T? {
//        get {
//            guard let data = object(forKey: key._key) as? Data else { return nil }
//
//            let decoder = JSONDecoder()
//            let dictionary = try! decoder.decode([String: T].self, from: data)
//            return dictionary["top"]
//        }
//        set {
//            guard let value = newValue else { return set(nil, forKey: key._key) }
//
//            let encoder = JSONEncoder()
//            let data = try! encoder.encode(["top": value])
//            set(data, forKey: key._key)
//
//        }
//    }
//}


//extension Room: DefaultsSerializable {
//    static var _defaults: ThemeModeBridge { return ThemeModeBridge() }
//    static var _defaultsArray: ThemeModeBridge { return ThemeModeBridge() }
//}
//
//class ThemeModeBridge: DefaultsBridge<Theme.Mode> {
//    override func save(key: String, value: Theme.Mode?, userDefaults: UserDefaults) {
//        userDefaults.set(value?.rawValue, forKey: key)
//    }
//
//    override func get(key: String, userDefaults: UserDefaults) -> Theme.Mode? {
//        return Theme.Mode(rawValue: userDefaults.integer(forKey: key))
//    }
//}


class SearchViewModel {
    var dataSource: [Room] = [] {
        didSet {
            dataSourceSubject.onNext(dataSource)
        }
    }
    
    var dataSourceSubject = BehaviorSubject<[Room]>(value: [])
    var querySourceSubject = BehaviorSubject<[Room]>(value: [])

    private let bag = DisposeBag()
    private var joinedPrivateChannels: [Room] = []
    
    private(set) var queryString: String?
    
    init() {
        
    }
    
    func startListenerList() {
        let onlineChannelList =
        FireStore.shared.publicChannelsSubject
            .map { $0.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) }
            
        let secretChannelsSubject =
            FireStore.shared.secretChannelsSubject
                .map { [weak self] items -> [Room] in
                    guard let `self` = self else { return [] }
                    return items.filter { room -> Bool in
                        return self.joinedPrivateChannels.contains { $0.name == room.name }
                    }
                } //merge the
                .map { $0.sorted(by: { $0.joinAt > $1.joinAt }) }

                
        Observable.combineLatest(onlineChannelList, secretChannelsSubject)
            .map { publicRooms, secretRooms -> [Room] in
                var rooms = publicRooms
                rooms.insert(contentsOf: secretRooms, at: 0)
                cdPrint("[SearchViewModel] publicRooms: \(publicRooms.count) secretRooms: \(secretRooms.count) total: \(rooms.count)")
                return rooms.filterDuplicates { $0.name }
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] list in
                self?.dataSource.removeAll()
                self?.dataSource.append(contentsOf: list)
                self?.query(self?.queryString)
            })
            .disposed(by: bag)
    }
    
    func query(_ string: String?) {
        queryString = string
        guard let string = string,
            !string.isEmpty else {
            querySourceSubject.onNext(dataSource)
            return
        }
        let result = dataSource
            .filter { $0.name.uppercased().contains(string.uppercased()) }
        querySourceSubject.onNext(result)
    }
    
    func previousRoom(_ current: String) -> Room? {
        guard !dataSource.isEmpty else {
            return nil
        }
        
        let index = dataSource.firstIndex(where: {
            $0.name == current
        }) ?? 0
        var previousIndex: Int {
            if index > 0 {
                return index - 1
            } else {
                //last index
                return dataSource.count - 1
            }
        }
        return dataSource[previousIndex]
    }
    
    func nextRoom(_ current: String) -> Room? {
        guard !dataSource.isEmpty else {
            return nil
        }
        
        let index = dataSource.firstIndex(where: {
            $0.name == current
        }) ?? 0
        var nextIndex: Int {
            if index < (dataSource.count - 1) {
                return index + 1
            } else {
                //first index
                return 0
            }
        }
        return dataSource[nextIndex]
    }
    
    func add(private channelName: String) {
        guard channelName.isPrivate else {
            return
        }
        if var room = joinedPrivateChannels.first(where: { $0.name == channelName }) {
            //upate time interval
            room.updateJoinInterval()
        } else {
            joinedPrivateChannels.append(Room(name: channelName, user_count: 1))
        }
        
    }
}


extension Array {
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
}

