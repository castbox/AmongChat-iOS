//
//  Social.ProfileLookViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/2/2.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Social {
    
    class ProfileLookViewController: WalkieTalkie.ViewController {
        
        override var screenName: Logger.Screen.Node.Start {
            return .customize
        }
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_profile_back(), for: .normal)
            return btn
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.text = R.string.localizable.amongChatProfileCustomize()
            return lb
        }()
        
        private lazy var profileLookView: ProfileLookView = {
            let v = ProfileLookView()
            return v
        }()
        
        private lazy var segmentedButton: SegmentedButton = {
            let s = SegmentedButton()
            s.selectedIndexObservable
                .subscribe(onNext: { [weak self] (idx) in
                    guard let `self` = self else { return }
                    let offset = CGPoint(x: self.scrollView.bounds.width * CGFloat(idx), y: 0)
                    self.scrollView.setContentOffset(offset, animated: true)
                })
                .disposed(by: bag)
            return s
        }()
        
        private lazy var scrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            s.isPagingEnabled = true
            s.delegate = self
            return s
        }()
        
        private var pageIndex: Int = 0 {
            didSet {
                segmentedButton.updateSelectedIndex(pageIndex)
            }
        }
        
        private var decoCategories = [DecorationCategoryViewModel]() {
            didSet {
                setupDecoCategoryViewsLayout(decoCategoryViews: decoCategories.map(decoCategoryViewMapper(_:)))
                setupSegmentedButton(for: decoCategories)
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            fetchData()
            setupEvents()
        }
        
    }
    
}

private extension Social.ProfileLookViewController {
    
    // MARK: - UI action
    
    @objc
    private func onBackBtn() {
        navigationController?.popViewController()
    }
    
}

private extension Social.ProfileLookViewController {
    
    func setupLayout() {
        
        
        view.addSubviews(views: profileLookView, backBtn, titleLabel, segmentedButton, scrollView)
        
        profileLookView.snp.makeConstraints { (maker) in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(profileLookView.snp.width).multipliedBy(1)
        }
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(12)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
        
        segmentedButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(80.scalHValue)
            maker.top.equalTo(profileLookView.snp.bottom)
        }
        
        scrollView.snp.makeConstraints { (maker) in
            maker.top.equalTo(segmentedButton.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
    }
    
    func fetchData() {
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        Request.defaultProfileDecorations()
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (decorationDataList) in
                
                guard let `self` = self else { return }
                
                guard let list = decorationDataList else {
                    self.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    return
                }
                
                self.decoCategories = list.compactMap(self.decoCategoryViewModelMapper(_:))
                
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
    }
    
    func setupEvents() {
        
        Settings.shared.amongChatUserProfile.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (p) in
                p?.decorations.forEach({ (deco) in
                    self?.profileLookView.updateLook(deco)
                })
            })
            .disposed(by: bag)
        
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { () in
                Logger.Action.log(.profile_customize_imp)
            })
            .disposed(by: bag)

    }
    
    func decoCategoryViewModelMapper(_ decoCategory: Entity.DecorationCategory) -> DecorationCategoryViewModel? {
        let viewModel = DecorationCategoryViewModel(dataModel: decoCategory)
        return viewModel
    }
    
    func decoCategoryViewMapper(_ decoCategory: DecorationCategoryViewModel) -> UIView {
        let v = DecorationCategoryView(viewModel: decoCategory)
        v.onSelectDecoration = onDecorationSelect(_:)
        return v
    }
    
    func setupSegmentedButton(for decoCategories: [DecorationCategoryViewModel]) {
        segmentedButton.setTitles(titles: decoCategories.map({ $0.name }))
    }
    
    func setupDecoCategoryViewsLayout(decoCategoryViews: [UIView]) {
        
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        
        scrollView.addSubviews(decoCategoryViews)
        
        for (idx, v) in decoCategoryViews.enumerated() {
            
            v.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(view)
                maker.height.equalTo(scrollView)
                if idx == 0 {
                    maker.leading.equalToSuperview()
                } else if idx == decoCategoryViews.count - 1 {
                    maker.trailing.equalToSuperview()
                }
                
                if idx > 0,
                   let preView = decoCategoryViews.safe(idx - 1) {
                    maker.leading.equalTo(preView.snp.trailing)
                }
            }
            
        }
        
        scrollView.layoutIfNeeded()
    }
    
    func onDecorationSelect(_ decoration: DecorationViewModel) -> Single<Bool> {
        
        Logger.Action.log(.profile_customize_clk, categoryValue: decoration.decorationType.rawValue, decoration.decoration.id.string)
        
        if decoration.decorationType == .pet {
            Logger.Action.log(.profile_customize_pet_get, decoration.decoration.id.string)
        }
        
        let signal: Single<Bool>
        
        if decoration.selected {
            signal = updateDecorationSelection(decoration, selected: false)
        } else {
            
            if decoration.locked {
                
                signal = unlockDecorationStep1(decoration)
                    .flatMap({ [weak self] (_) -> Single<Bool> in
                        
                        guard let `self` = self else {
                            return Single.error(MsgError.default)
                        }
                        
                        guard decoration.decoration.unlockType != .pay else {
                            return self.updateDecorationSelection(decoration, selected: true)
                        }
                        
                        return self.unlockDecorationStep2(decoration)
                    })
                    .do(onSuccess: { (_) in
                        if decoration.decorationType == .pet {
                            Logger.Action.log(.profile_customize_pet_get_success, decoration.decoration.id.string)
                        }
                    })
                
            } else {
                signal = updateDecorationSelection(decoration, selected: true)
            }
            
        }
        
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        
        scrollView.isUserInteractionEnabled = false
        
        let completion = { [weak self] in
            hudRemoval()
            self?.scrollView.isUserInteractionEnabled = true
        }
        
        return signal
            .observeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { [weak self] (success) in
                self?.profileLookView.updateLook(decoration)
                Settings.shared.updateProfile()
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
            }, onDispose: {
                completion()
            })
        
    }
    
    func unlockDecorationStep1(_ decoration: DecorationViewModel) -> Single<Bool> {
        switch decoration.decoration.unlockType {
        case .rewarded:
            Logger.Action.log(.profile_customize_rewarded_get, categoryValue: decoration.decorationType.rawValue, decoration.decoration.id.string)
            return watchRewardedVideo()
                .do(onSuccess: { (_) in
                    Logger.Action.log(.profile_customize_rewarded_get_success, categoryValue: decoration.decorationType.rawValue, decoration.decoration.id.string)
                })
            
        case .premium:
            return upgradePro()

        case .pay:
            return buy(decoration)
            
        default:
            return Single.error(MsgError.default)
        }
    }
    
    func unlockDecorationStep2(_ decoration: DecorationViewModel) -> Single<Bool> {
        return Request.unlockProfileDecoration(decoration.decoration)
            .observeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { (success) in
                guard success else { return }
                decoration.unlock()
            })
            .flatMap { [weak self] (success) in
                
                guard let `self` = self,
                      success else {
                    return Single.error(MsgError.default)
                }
                
                return self.updateDecorationSelection(decoration, selected: true)
            }
    }
    
    func updateDecorationSelection(_ decoration: DecorationViewModel, selected: Bool) -> Single<Bool> {
        return Request.updateProfileDecoration(decoration: decoration.decoration, selected: selected)
            .observeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { (success) in
                guard success else { return }
                
                decoration.selected = selected
                if decoration.decorationType == .pet {
                    let action: Logger.Action.EventName = selected ? .profile_customize_pet_equip : .profile_customize_pet_remove
                    Logger.Action.log(action, decoration.decoration.id.string)
                }
            })
    }
    
    func watchRewardedVideo() -> Single<Bool> {
        return AdsManager.shared.earnARewardOfVideo(fromVC: self, adPosition: .unlockAvatar)
            .take(1)
            .flatMap({ Observable.just(true) })
            .asSingle()
    }
    
    func upgradePro() -> Single<Bool> {
        
        guard !Settings.shared.isProValue.value else {
            return Single.just(true)
        }
        
        let purchasedObservable = Single<Bool>.create { [weak self] (subscriber) -> Disposable in
            
            guard let `self` = self else {
                return Disposables.create()
            }
            
            self.presentPremiumView(source: .profile_look) { (purchased) in
                subscriber(.success(purchased))
            }
            
            return Disposables.create()
        }
        
        return purchasedObservable
            .flatMap { (purchased) in
                
                guard purchased else {
                    return Single.error(MsgError.default)
                }
                
                return Settings.shared.isProValue.replay()
                    .filter { $0 }
                    .take(1)
                    .timeout(.seconds(10), scheduler: MainScheduler.asyncInstance)
                    .asSingle()
            }
    }
    
    func buy(_ decoration: DecorationViewModel) -> Single<Bool> {
        
        guard let product = decoration.iapProduct else {
            return Single.error(MsgError.default)
        }
        
        let purchasedOb = Single<Bool>.create { (subscriber) -> Disposable in
            
            IAP.ProductDealer.pay(product, onState: { (state, error) in
                cdPrint("ProductDealer state: \(state.rawValue)")
                switch state {
                case .purchased, .restored:
                    subscriber(.success(true))
                    
                case .failed:
                    cdPrint("Purchase failed")
                    subscriber(.success(false))
                default:
                    ()
                }
            })
            
            return Disposables.create()
        }
        
        return purchasedOb.flatMap({ (purchased) in
            
            guard purchased else {
                return Single.error(MsgError.default)
            }
            
            return Request.uploadReceipt(restore: false)
                .flatMap { Single.just(true) }
        })
        
    }
    
}

extension Social.ProfileLookViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }
    
}
