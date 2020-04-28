//
//  AddChannelViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import JXPagingView
import JXCategoryView
import JXSegmentedView
import IQKeyboardManagerSwift

class AddChannelViewController: ViewController {
    private var pagingView: JXPagingView!
    private var segmentedView: JXSegmentedView!
    private var secretContainer: SecretChannelContainer!
    private var globalContainer: GlobalChannelContainer!
    private let dataSource: JXSegmentedTitleDataSource = JXSegmentedTitleDataSource()
    private var isScrollDismiss: Bool = false
    var joinChannel: (String, Bool) -> Void = { _, _ in }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        IQKeyboardManager.shared.enable = true
//        Logger.PageShow.log(.secret_channel_create_pop_imp)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        IQKeyboardManager.shared.enable = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pagingView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height())
    }
    
    func shouldDismiss() -> Bool {
        var isFirstResponder: Bool {
            if segmentedView.selectedIndex == 0 {
                return secretContainer?.isFirstResponder ?? false
            }
            return globalContainer?.isFirstResponder ?? false
        }
        if isFirstResponder {
            self.view.endEditing(true)
            return false
        }
        return true
    }
}

extension AddChannelViewController: JXPagingViewDelegate {
    
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int {
        return 0
    }
    
    func tableHeaderView(in pagingView: JXPagingView) -> UIView {
        return UIView()
    }
    
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        return 50
    }
    
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        return segmentedView
    }
    
    func numberOfLists(in pagingView: JXPagingView) -> Int {
        return 2
    }
    
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        if index == 0 {
            if globalContainer.isFirstResponder {
                view.endEditing(true)
            }
            return secretContainer
        } else {
            if secretContainer.isFirstResponder {
                view.endEditing(true)
            }
            return globalContainer
        }
    }
    
    func mainTableViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -100 && !isScrollDismiss {
            isScrollDismiss = true
            self.dismiss(animated: true)
        }
    }
}

extension JXPagingListContainerView: JXSegmentedViewListContainer {}

extension AddChannelViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        if index == 0 {
            if globalContainer.isFirstResponder {
                view.endEditing(true)
            }
        } else {
            if secretContainer.isFirstResponder {
                view.endEditing(true)
            }
        }
    }
}

extension AddChannelViewController {
    
    func dismiss() {
        Logger.PageShow.log(.secret_channel_create_pop_close)
        hideModal()
    }
    
    func bindSubviewEvent() {
        secretContainer.joinChannel = { [weak self] name, autoShare in
            self?.joinChannel(name, autoShare)
            self?.dismiss()
        }
        
        globalContainer.joinChannel = { [weak self] name, autoShare in
            self?.joinChannel(name, autoShare)
            self?.dismiss()
        }
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                UIView.animate(withDuration: 0) {
                    self.view.top = Frame.Screen.height - self.height() - keyboardVisibleHeight / 3
                }
            })
            .disposed(by: bag)

    }
    
    func configureSubview() {
        
        navigationController?.view.backgroundColor = .clear
        view.backgroundColor = .clear
        
        secretContainer = SecretChannelContainer()
        secretContainer.viewController = self
        globalContainer = GlobalChannelContainer()
        
        pagingView = JXPagingView(delegate: self)
        pagingView.defaultSelectedIndex = 1
        pagingView.listContainerView.backgroundColor = .clear
        pagingView.mainTableView.backgroundColor = .clear
        pagingView.mainTableView.keyboardDismissMode = .onDrag
        view.addSubview(pagingView)
        
        //
        dataSource.titles = [R.string.localizable.addChannelSecretTitle(), R.string.localizable.addChannelGlobalTitle()]
        dataSource.titleSelectedColor = UIColor.theme(.textBlackAlpha(0.32))
        dataSource.titleNormalFont = R.font.nunitoSemiBold(size: 16)!
        dataSource.titleNormalColor = UIColor.theme(.textBlack)
        dataSource.isTitleColorGradientEnabled = true
        dataSource.isTitleZoomEnabled = true
        dataSource.isItemSpacingAverageEnabled = false
        dataSource.itemSpacing = 25
        
        segmentedView = JXSegmentedView(frame: CGRect(x: 0, y: 56, width: Frame.Screen.width, height: 50))
        segmentedView.backgroundColor = UIColor.theme(.backgroundWhite)

        segmentedView.contentEdgeInsetLeft = 25
        segmentedView.dataSource = dataSource
        segmentedView.delegate = self
        segmentedView.defaultSelectedIndex = 0
        
        let lineView = JXSegmentedIndicatorLineView()
        lineView.indicatorColor = UIColor(hex: 0x6788D3)!
        lineView.indicatorWidth = 62
//        segmentedView.innerItemSpacing = 5
        segmentedView.indicators = [lineView]
        segmentedView.listContainer = pagingView.listContainerView
    }
}

extension AddChannelViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        let descHeight = R.string.localizable.addChannelSecretTipsDes().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.blackOpsOneRegular(size: 14)!, lineSpacing: 0).height
        let secDescHeight = R.string.localizable.addChannelSecretCreateTipsDes().boundingRect(with: CGSize(width: Frame.Screen.width - 25 * 2, height: 200), font: R.font.blackOpsOneRegular(size: 14)!, lineSpacing: 0).height
        let contentHeight = max(115 + descHeight + 134 + secDescHeight + secDescHeight + 145, 446)
        return contentHeight + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 15
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return shouldDismiss()
    }
}
