//
//  Feed.SelectVideoViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/25.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol FeedVideoSelective: UIViewController {
    var hasSelected: Observable<Void> { get }
    var scrollView: UIScrollView { get }
    func clearSelection()
    func getVideo() -> Observable<URL>
}

extension Feed {
    
    class SelectVideoViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            let lb = n.titleLabel
            lb.text = R.string.localizable.feedPostTitle()
            return n
        }()
        
        private typealias SegmentedButton = Social.ProfileLookViewController.SegmentedButton
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
        
        private let pageIndex = BehaviorRelay(value: 0)
        
        private lazy var tabDataSoure: [(String, FeedVideoSelective)] = {
            
            var dataSource: [(String, FeedVideoSelective)] = [
                (R.string.localizable.feedLibraryTitle(), videoLibraryVC)
            ]
            
            return dataSource
        }()
        
        private var currentSelection: (FeedVideoSelective, Void)? = nil
        
        private lazy var bottomGradientView: FansGroup.Views.BottomGradientButton = {
            let v = FansGroup.Views.BottomGradientButton()
            v.button.setTitle(R.string.localizable.amongChatLoginNext(), for: .normal)
            v.button.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.next()
                })
                .disposed(by: bag)
            v.button.isEnabled = false
            return v
        }()
        
        private lazy var videoLibraryVC = VideoLibraryViewController()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
        }
        
    }
    
}

extension Feed.SelectVideoViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, segmentedButton, scrollView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        segmentedButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(60)
            maker.top.equalTo(navView.snp.bottom)
        }
        
        scrollView.snp.makeConstraints { (maker) in
            maker.top.equalTo(segmentedButton.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        segmentedButton.setTitles(titles: tabDataSoure.map({ $0.0 }))
        
        for (idx, tuple) in tabDataSoure.enumerated() {
            
            let vc = tuple.1
            
            addChild(vc)
            scrollView.addSubview(vc.view)
            vc.view.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(view)
                maker.height.equalToSuperview()
                if idx == 0 {
                    maker.leading.equalToSuperview()
                }
                
                if idx == tabDataSoure.count - 1 {
                    maker.trailing.equalToSuperview()
                }
                
                if idx > 0,
                   let pre = tabDataSoure.safe(idx - 1)?.1 {
                    maker.leading.equalTo(pre.view.snp.trailing)
                }
                
            }
            vc.didMove(toParent: self)
            vc.scrollView.contentInset = UIEdgeInsets(top: 13, left: 0, bottom: 134, right: 0)

        }
        
        scrollView.layoutIfNeeded()
        
    }
    
    private func setUpEvents() {
        
        Observable.merge(
            tabDataSoure.map { t in
                t.1.hasSelected.map { (_) in
                    (t.1, ())
                }
            }
        )
        .distinctUntilChanged({ (old, new) -> Bool in
            return old.0 == new.0
        })
        .subscribe(onNext: { [weak self] tuple in
            self?.currentSelection?.0.clearSelection()
            self?.currentSelection = tuple
            self?.bottomGradientView.button.isEnabled = true
        })
        .disposed(by: bag)
        
    }
    
    private func next() {
        
        guard let selection = currentSelection else { return }
        let hudRemoval = self.view.raft.show(.loading, userInteractionEnabled: true)

        selection.0.getVideo()
            .asSingle()
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (url) in
                
                let vc = Feed.SelectTopicViewController(videoURL: url)
                self?.navigationController?.pushViewController(vc)
            })
            .disposed(by: bag)
        
    }
}

extension Feed.SelectVideoViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        pageIndex.accept(Int(scrollView.contentOffset.x / scrollView.frame.size.width))
    }
    
}
