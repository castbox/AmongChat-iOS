//
//  AmongChat.Room.EmojiViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension AmongChat.Room {
    
    class EmojiViewModel {
        var SHEER_ITEM_HEIGHT: CGFloat = 64
        var SHEET_ITEM_SPACE: CGFloat = 0
        
        var sheetHeight: CGFloat {
            return SHEER_ITEM_HEIGHT * 2
        }
        private var allSourceObservable = BehaviorSubject<[Entity.EmojiItem]>(value: [])
        
        var dataSourceSubject = BehaviorSubject<[[Entity.EmojiItem]]>(value: [[]])
        var dataSource: [[Entity.EmojiItem]] = []
        var itemIsSelectable: Bool = true {
            didSet {
                guard let source = try? allSourceObservable.value() else {
                    return
                }
                let newSource = source.map { item -> Entity.EmojiItem in
                    var item = item
                    item.isEnable = itemIsSelectable
                    return item
                }
                allSourceObservable.onNext(newSource)
            }
        }
        
        private let bag = DisposeBag()
        
        init() {
            Settings.shared.globalSetting.replay()
                .map { $0?.emoji }
                .filterNilAndEmpty()
                .bind(to: allSourceObservable)
                .disposed(by: bag)
            
            allSourceObservable
                .map { $0.filter { $0.price == 0 }.chunked(into: 10) }
                .map { items -> [[Entity.EmojiItem]] in
                    var items = items
                    //补齐
                    if var last = items.last, last.count < 10 {
                        last.append(contentsOf: Array(repeating: Entity.EmojiItem.empty(), count: 10 - last.count))
                        _ = items.removeLast()
                        items.append(last)
                    }
                    return items
                }
                .do(onNext: { [weak self] items in
                    self?.dataSource = items
                })
                .bind(to: dataSourceSubject)
                .disposed(by: bag)
        }
    }
}

//extension Array {
//    func chunked(into size: Int) -> [[Element]] {
//        return stride(from: 0, to: count, by: size).map {
//            Array(self[$0 ..< Swift.min($0 + size, count)])
//        }
//    }
//}
