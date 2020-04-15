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
    let name: String
    let user_count: Int
}

class SearchViewModel {
    var dataSource: [Room] = [] {
        didSet {
            dataSourceSubject.onNext(dataSource)
        }
    }
    
    var dataSourceSubject = BehaviorSubject<[Room]>(value: [])
    var querySourceSubject = BehaviorSubject<[Room]>(value: [])

    private let bag = DisposeBag()
    
    private(set) var queryString: String?
    
    init() {

    }
    
    func startListenerList() {
        FireStore.shared.onlineChannelList()
            .observeOn(MainScheduler.asyncInstance)
            .map { $0.sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) }
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
