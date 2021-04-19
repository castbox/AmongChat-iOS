//
//  FansGroup.GroupsViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/30.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup {
    
    class GroupsViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatGroup()
            return n
        }()
        
        private lazy var segmentedButton: SegmentedButton = {
            let s = SegmentedButton()
            s.selectedIndexObservable
                .subscribe(onNext: { [weak self] (idx) in
                    Logger.Action.log(.group_list_tab_clk, categoryValue: idx == 0 ? "my_group" : "explore")
                    guard let `self` = self else { return }
                    let offset = CGPoint(x: self.layoutScrollView.bounds.width * CGFloat(idx), y: 0)
                    self.layoutScrollView.setContentOffset(offset, animated: true)
                })
                .disposed(by: bag)
            s.setTitles(titles: [R.string.localizable.amongChatMyGroups(), R.string.localizable.amongChatExplore()])
            return s
        }()
        
        private lazy var getVerifiedView: UIView = {
            let v = UIView()
            
            let icon = UIImageView(image: R.image.ac_group_get_verirfied())
            
            let label: UILabel = {
                let l = UILabel()
                l.font = R.font.nunitoExtraBold(size: 16)
                l.textColor = UIColor(hex6: 0xFFFFFF)
                l.numberOfLines = 2
                l.text = R.string.localizable.amongChatGroupGetVerfied()
                l.adjustsFontSizeToFitWidth = true
                return l
            }()
            
            let goBtn: UIButton = {
                let btn = UIButton(type: .custom)
                btn.layer.cornerRadius = 16
                btn.setTitle(R.string.localizable.bigGo(), for: .normal)
                btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
                btn.layer.cornerRadius = 16
                btn.layer.borderWidth = 2
                btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
                btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 26, bottom: 0, right: 26)
                btn.rx.controlEvent(.primaryActionTriggered)
                    .subscribe(onNext: { [weak self] (_) in
                        Logger.Action.log(.group_list_clk, categoryValue: "go_verify")
                        self?.getVerified()
                    })
                    .disposed(by: bag)
                return btn
            }()
            
            v.addSubviews(views: icon, label, goBtn)
            
            icon.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(20)
                maker.centerY.equalToSuperview()
            }
            
            label.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(icon.snp.trailing).offset(8)
                maker.trailing.equalTo(goBtn.snp.leading).offset(-20)
            }
            
            goBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.height.equalTo(32)
                maker.trailing.equalTo(-20)
            }
            
            goBtn.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            goBtn.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            label.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            label.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            
            return v
        }()
        
        private lazy var layoutScrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            s.isPagingEnabled = true
            s.delegate = self
            return s
        }()
        
        private lazy var gotoCreateButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.amongChatCreateNewGroup(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    let vc = FansGroup.CreateGroupViewController()
                    self?.navigationController?.pushViewController(vc)
                    Logger.Action.log(.group_list_clk, categoryValue: "create")
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = Social.ChooseGame.bottomGradientView()
            v.addSubviews(views: gotoCreateButton)
            gotoCreateButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(-33)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            return v
        }()
        
        private var pageIndex: Int = 0 {
            didSet {
                segmentedButton.updateSelectedIndex(pageIndex)
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            layoutScrollView.contentSize = CGSize(width: layoutScrollView.bounds.width * 2, height: layoutScrollView.bounds.height)
        }
    }
    
}

extension FansGroup.GroupsViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, segmentedButton, layoutScrollView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        segmentedButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(navView.snp.bottom)
            maker.height.equalTo(60)
        }
        
        let scrollLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(scrollLayoutGuide)
        
        if let p = Settings.shared.amongChatUserProfile.value,
           !(p.isVerified ?? false) {
            
            view.addSubview(getVerifiedView)
            getVerifiedView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(70)
                maker.top.equalTo(segmentedButton.snp.bottom)
            }
            
            scrollLayoutGuide.snp.makeConstraints { (maker) in
                maker.top.equalTo(getVerifiedView.snp.bottom)
                maker.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            bottomGradientView.isHidden = true
        } else {
            bottomGradientView.isHidden = false
            scrollLayoutGuide.snp.makeConstraints { (maker) in
                maker.top.equalTo(segmentedButton.snp.bottom)
                maker.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
        }
        
        layoutScrollView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(scrollLayoutGuide)
        }
        
        let myGroupList = FansGroup.GroupListViewController(source: .myGroups)
        addChild(myGroupList)
        layoutScrollView.addSubview(myGroupList.view)
        myGroupList.view.snp.makeConstraints { (maker) in
            maker.leading.top.bottom.equalToSuperview()
            maker.width.equalTo(view.snp.width)
            maker.height.equalToSuperview()
        }
        myGroupList.didMove(toParent: self)
        
        myGroupList.view.addSubview(bottomGradientView)
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
        }
                
        let allGroupList = FansGroup.GroupListViewController(source: .allGroups)
        addChild(allGroupList)
        layoutScrollView.addSubview(allGroupList.view)
        allGroupList.view.snp.makeConstraints { (maker) in
            maker.top.bottom.trailing.equalToSuperview()
            maker.leading.equalTo(myGroupList.view.snp.trailing)
            maker.width.equalTo(view.snp.width)
            maker.height.equalToSuperview()
        }
        allGroupList.didMove(toParent: self)
    }
    
    private func getVerified() {
        
        guard AmongChat.Login.canDoLoginEvent(style: .applyVerify) else {
            return
        }
        self.open(urlSting: "https://docs.google.com/forms/d/e/1FAIpQLSeTzpMgWikmqajPHbEBAstCdFVB4Xo1CjYDc29wj4zSJq99Kg/viewform")
    }
    
    private func setUpEvents() {
        rx.viewDidAppear.take(1)
            .subscribe(onNext: { (_) in
                Logger.Action.log(.group_list_imp)
            })
            .disposed(by: bag)
    }
}

extension FansGroup.GroupsViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
    }
    
}

extension FansGroup.GroupsViewController {
    
    class SegmentedButton: UIView {
        
        private let bag = DisposeBag()
        
        private lazy var indicatorContainer: UIView = {
            let v = UIView()
            return v
        }()
        
        private lazy var selectedIndicator: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0xFFF000)
            v.layer.cornerRadius = 2.5
            v.clipsToBounds = true
            return v
        }()
        
        private var buttons = [UIButton]()
        
        private var selectedBtn: UIButton? = nil
        
        private let selectedIndexrRelay = BehaviorRelay<Int>(value: 0)
        
        var selectedIndexObservable: Observable<Int> {
            return selectedIndexrRelay.asObservable().distinctUntilChanged()
        }
        
        init() {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            indicatorContainer.addSubview(selectedIndicator)
            
            addSubviews(views: indicatorContainer)
            
            indicatorContainer.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(-12)
            }
        }
        
        func setTitles(titles: [String]) {
            
            buttons.forEach({ (btn) in
                btn.removeFromSuperview()
            })
            
            buttons = titles.enumerated().map { (idx, title) -> UIButton in
                let btn = UIButton(type: .custom)
                btn.setTitleColor(UIColor(hex6: 0x595959), for: .normal)
                btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .selected)
                btn.titleLabel?.font = R.font.nunitoExtraBold(size: 24)
                btn.setTitle(title, for: .normal)
                btn.rx.controlEvent(.primaryActionTriggered)
                    .subscribe(onNext: { [weak self] () in
                        self?.updateSelectedIndex(idx)
                    })
                    .disposed(by: bag)
                
                return btn
            }
            
            addSubviews(buttons)
            
            for (idx, btn) in buttons.enumerated() {
                
                btn.snp.makeConstraints { (maker) in
                    maker.top.equalTo(8)
                    if idx == 0 {
                        maker.leading.equalToSuperview()
                    } else if idx == buttons.count - 1 {
                        maker.trailing.greaterThanOrEqualToSuperview()
                    }
                    
                    if idx > 0,
                       let pre = buttons.safe(idx - 1) {
                        maker.leading.equalTo(pre.snp.trailing)
                    }
                    maker.height.equalTo(33)
                    maker.width.equalTo(snp.width).dividedBy(buttons.count)
                    
                }
                
            }
            
            updateSelectedIndex(0)
        }
        
        func updateSelectedIndex(_ index: Int) {
            
            guard let button = buttons.safe(index) else {
                return
            }
            
            guard selectedBtn != button else { return }
            
            selectedIndicator.snp.remakeConstraints { (maker) in
                maker.centerX.equalTo(button)
                maker.width.equalTo(24)
                maker.height.equalTo(5)
                maker.top.bottom.equalTo(indicatorContainer)
            }
            
            UIView.animate(withDuration: 0.25) { [weak self] in
                button.isSelected = true
                self?.selectedBtn?.isSelected = false
                self?.selectedBtn = button
                
                self?.indicatorContainer.layoutIfNeeded()
            }
            
            selectedIndexrRelay.accept(index)
        }
        
        func buttonOf(_ index: Int) -> UIView? {
            return buttons.safe(index)
        }
    }
    
}
