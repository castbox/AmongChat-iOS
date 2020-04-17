//
//  FrozenButton.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class FrozenButton: UIButton {
    private var timer: SwiftTimer?
    private var previousInterval: TimeInterval = 0
    var tapHandler: () -> Void = { }
    
    let bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bindSubviewEvent()
    }
    
    func bindSubviewEvent() {
        self.rx.tap.asDriver()
            .debounce(.fromSeconds(0.5))
            .do(onNext: { [weak self] _ in
                self?.tapHandler()
                self?.isEnabled = false
            })
//            .delay(.seconds(2))
            .drive(onNext: { [weak self] _ in
                self?.isEnabled = true
            })
            .disposed(by: bag)
    }
    
//    func startTimer() {
//        timer = SwiftTimer(interval: .seconds(2)) { timer in
//
//        }
//        timer?.start()
//    }
    
//    func canTap() -> Bool {
//        let time = Date().timeIntervalSince1970
//        let result = (time - previousInterval) > 2
//        previousInterval = time
//        return result
//    }
}
