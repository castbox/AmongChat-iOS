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

class SearchViewModel {
    var dataSource: [Room] = [] {
        didSet {
            dataSourceSubject.onNext(dataSource)
        }
    }
    
    var dataSourceSubject = BehaviorSubject<[Room]>(value: [])
    var querySourceSubject = BehaviorSubject<[Room]>(value: [])
    var mode: Mode = .public {
        didSet {
            updateQueryStorce()
        }
    }
    
    private let bag = DisposeBag()
    private var joinedPrivateChannels: [Room] = [] {
        didSet {
            cdPrint("[SearchViewModel] joinedPrivateChannels: \(joinedPrivateChannels)")
            let persistenceRooms = joinedPrivateChannels.filter { $0.persistence == true }
            Defaults[\.secretChannels] = persistenceRooms
            cdPrint("[SearchViewModel] persistenceRooms: \(persistenceRooms)")

        }
    }
    
    private(set) var queryString: String?
    
    init() {
        joinedPrivateChannels = Defaults[\.secretChannels]
        cdPrint("[SearchViewModel] init joinedPrivateChannels: \(joinedPrivateChannels)")
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
                .debug()
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
                self?.updateQueryStorce()
            })
            .disposed(by: bag)
    }
    
    private func updateQueryStorce() {
        query(queryString)
    }
    
    func query(_ string: String?) {
        queryString = string
        
        let mode = self.mode
        let modeResult = dataSource
            .filter{ $0.name.channelType == mode.channelType }
        var result: [Room] = []
        if let string = string, !string.isEmpty  {
            result = modeResult
                .filter { $0.name.uppercased().contains(string.uppercased()) }
        } else {
            result = modeResult
        }
        if mode == .private {
            result.append(.add)
        }
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
            var channels = joinedPrivateChannels
            channels.append(FireStore.shared.findValidRoom(with: channelName))
            joinedPrivateChannels = channels
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

