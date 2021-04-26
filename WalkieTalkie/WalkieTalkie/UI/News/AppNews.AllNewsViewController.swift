//
//  AppNews.AllNewsViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension AppNews {
    
    class AllNewsViewController: WalkieTalkie.ViewController {
        
        enum NewsType {
            case system
            case social
            case groupRequest
            
            var title: String {
                switch self {
                case .system:
                    return R.string.localizable.amongChatNewsSystem()
                case .social:
                    return R.string.localizable.amongChatNewsSocial()
                case .groupRequest:
                    return R.string.localizable.amongChatNewsGroupRequests()
                }
            }
            
            var vC: UIViewController {
                
                switch self {
                case .system:
                    return SystemNewsViewController()
                case .social:
                    return SocialNewsViewController()
                case .groupRequest:
                    return GroupRequestsListViewController()
                }
                
            }
            
        }
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_profile_back(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.text = R.string.localizable.amongChatNewsAllNewsTitle()
            return lb
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
        
        private var pageIndex: Int = 0 {
            didSet {
                segmentedButton.updateSelectedIndex(pageIndex)
            }
        }
        
        private let dataSet: [NewsType] = {
            if let p = Settings.shared.amongChatUserProfile.value,
               !(p.isVerified ?? false) {
                return [.system, .social]
            } else {
                return [.system, .social, .groupRequest]
            }
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvents()
        }
        
    }
    
}

extension AppNews.AllNewsViewController {
    
    func setupLayout() {
        
        view.addSubviews(views: backBtn, titleLabel, segmentedButton, scrollView)
        
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
            maker.height.equalTo(60)
            maker.top.equalTo(navLayoutGuide.snp.bottom)
        }
        
        scrollView.snp.makeConstraints { (maker) in
            maker.top.equalTo(segmentedButton.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        segmentedButton.setTitles(titles: dataSet.map({ $0.title }))
        
        let vCs = dataSet.map { $0.vC }
        
        for (idx, vC) in vCs.enumerated() {
                        
            addChild(vC)
            scrollView.addSubview(vC.view)
            vC.view.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(view)
                maker.height.equalToSuperview()
                if idx == 0 {
                    maker.leading.equalToSuperview()
                } else if idx == dataSet.count - 1 {
                    maker.trailing.equalToSuperview()
                }
                
                if idx > 0,
                   let preView = vCs.safe(idx - 1)?.view {
                    maker.leading.equalTo(preView.snp.trailing)
                }
            }
            vC.didMove(toParent: self)
            
        }
        
        scrollView.layoutIfNeeded()
        
    }
    
    func setupEvents() {
        
    }
    
}

extension AppNews.AllNewsViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }
    
}
