//
//  PremiumViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SnapKit

class PremiumViewController: ViewController {
    
    private lazy var iapTipsLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.numberOfLines = 0
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 12)
        lb.isHidden = true
        return lb
    }()
    private var productMaps: [String: IAP.Product] = [:]
    
    var source: Logger.IAP.ActionSource?
    var dismissHandler: ((_ purchased: Bool) -> Void)?
    var didSelectProducts: (String) -> Void = { _ in }
    
    private let isPuchasingState = BehaviorSubject<Bool>.init(value: false)
    
    override var screenName: Logger.Screen.Node.Start {
        return .premium
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let s = self.source, s != .first_open {
            Logger.IAP.logImp(s)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let s = self.source, s != .first_open  {
            Logger.IAP.logClose(s)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
        setupProduct()
    }
    
    private func dismissSelf(purchased: Bool = false) {
        if let handler = dismissHandler {
            handler(purchased)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

extension PremiumViewController {
    
    private func setupProduct() {
        IAP.productsValue
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (map) in
            guard let `self` = self else { return }
            self.productMaps = map
            })
            .disposed(by: bag)
    }
    
    //for
    
    func buy(identifier: String) {
                
        if let s = self.source {
            Logger.IAP.logPurchase(productId: identifier, source: s)
        }
        
        view.isUserInteractionEnabled = false
        let removeHUDBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        
        isPuchasingState.onNext(true)
        IAP.ProductFetcher.fetchProducts(of: [identifier]) { [weak self] (error, productMap) in
            guard let product = productMap[identifier] else {
                self?.isPuchasingState.onNext(false)
                DispatchQueue.main.async {
                    removeBlock()
                }
                if let s = self?.source {
                    Logger.IAP.logPurchaseFailByIdentifier(identifier: identifier, source: s)
                }
                return
            }
            IAP.ProductDealer.pay(product, onState: { [weak self] (state, error) in
                cdPrint("ProductDealer state: \(state.rawValue)")
                switch state {
                case .purchased, .restored:
                    Settings.shared.isProValue.value = true
                    Defaults[\.purchasedItemsKey] = identifier
                    self?.isPuchasingState.onNext(false)
                    if let s = self?.source {
                        Logger.IAP.logPurchaseResult(product: product.skProduct, source: s, isSuccess: true)
                    }
                    DispatchQueue.main.async { [weak self] in
                        removeBlock()
                        self?.dismissSelf(purchased: true)
                    }
                case .failed:
                    self?.isPuchasingState.onNext(false)
                    NSLog("Purchase failed")
                    DispatchQueue.main.async {
                        removeBlock()
                    }
                    if let s = self?.source {
                        Logger.IAP.logPurchaseResult(product: product.skProduct, source: s, isSuccess: false)
                    }
                default:
                    break
                }
            })
        }
    }
    
    func bindSubviewEvent() {
        
    }
    
    func configureSubview() {
    }
}
