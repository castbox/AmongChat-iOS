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

struct Room: Codable {
    let channel_name: String
    let user_count: Int
}

class SearchViewModel {
    var dataSource: [Room] = []
    var querySourceSubject = BehaviorSubject<[Room]>(value: [])
    let bag = DisposeBag()
    private(set) var queryString: String?
    
    init() {

    }
    
    func startListenerList() {
        Observable.combineLatest(FireStore.shared.onlineChannelList(), FireStore.shared.hotChannelList())
            .map { (onlineRooms, hotRooms) -> [Room] in
                var room: [Room] = []
                room.append(contentsOf: onlineRooms)
                room.append(contentsOf: hotRooms)
                room.sort { $0.channel_name.localizedStandardCompare($1.channel_name) == .orderedAscending }
                return room.filterDuplicates { $0.channel_name }
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] list in
                self?.dataSource.removeAll()
                self?.dataSource.append(contentsOf: list)
//                self?.querySourceSubject.
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
            .filter { $0.channel_name.uppercased().contains(string.uppercased()) }
        querySourceSubject.onNext(result)
    }
    
    func previousRoom(_ current: String) -> Room? {
        let index = dataSource.firstIndex(where: {
            $0.channel_name == current
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
        let index = dataSource.firstIndex(where: {
            $0.channel_name == current
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
