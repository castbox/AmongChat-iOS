//
//  Modal.Cover.swift
//  Castbox
//
//  Created by lazy on 2018/12/21.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit
import RxSwift

extension Modal {
    
    class Cover: UIView {
        
        private let bag = DisposeBag()
        
        var onTapped: (() -> Void)?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .black
            
            didInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func didInit() {
            
            weak var welf = self
            
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            
            tap.rx.event.asObservable()
                .map({ _ in () })
                .subscribe(onNext: { _ in
                    welf?.onClickVew()
                })
                .disposed(by: bag)
        }
        
        func onClickVew() {
            self.onTapped?()
        }
    }
}
