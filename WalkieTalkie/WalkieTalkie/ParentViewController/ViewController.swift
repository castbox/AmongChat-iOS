//
//  ViewController.swift
//  xWallet_ios
//
//  Created by Wilson on 2019/1/20.
//  Copyright © 2019 Anmobi inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    var isNavigationBarHiddenWhenAppear = false {
        didSet {
            if isNavigationBarHiddenWhenAppear {
                if #available(iOS 11.0, *) {
                    
                }
                else {
                    automaticallyAdjustsScrollViewInsets = false
                }
            }
        }
    }
    /**
     设置 statusBar 的初始hide状态
     如果 初始状态为NO, 然后将 statusBarHiddenWhenAppear = YES
     则, 会在viewWillAppear中执行 setNeedsStatusBarAppearanceUpdate 并且有一个平滑的Hide动画.
     
     Default is No.
     */
    var isInitialStatusBarHidden = false
    var isStatusBarHiddenWhenAppear = false //default is false
    var isHidesBottomBarWhenPushed: Bool {
        return true
    }
    var isNavigationBarHidden: Bool {
        set { setNavigationBarHidden(newValue, animated: false) }
        get { return navigationController!.isNavigationBarHidden }
    }
    var statusBarStyle: UIStatusBarStyle = .lightContent
    
    /**
     是否为第一次设置 statusBar hidden 的值
     如果是第一次, 则会更新 initialStatusBarHidden 的值
     并且再次调用 setNeedsStatusBarAppearanceUpdate
     来达到平滑的隐藏或者显示statusBar的目的
     */
    private var isFirstToUpdateStatusForStatusBar: Bool = true
    
    let disposeBag = DisposeBag()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = isHidesBottomBarWhenPushed
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.hidesBottomBarWhenPushed = isHidesBottomBarWhenPushed
    }
    
    deinit {
        debugPrint("[VIEWCONTROLLER-DEINIT]")
    }
    
    override func willMove(toParent parent: UIViewController?) {
        guard let navigation = parent as? UINavigationController else {
            super.willMove(toParent: parent)
            return
        }
        let count = navigation.viewControllers.count
        if count > 1 {
            //before controller
            let beforeLastController = navigation.viewControllers[count - 2] as? ViewController
            //set current to before
            beforeLastController?.isStatusBarHiddenWhenAppear = isStatusBarHiddenWhenAppear
        }
        super.willMove(toParent: parent)
    }

    // MARK: - Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if parent is UINavigationController {
            setNavigationBarHidden(isNavigationBarHiddenWhenAppear, animated: animated)
        }
        
        ///save the current statusBar hidden value
        if isInitialStatusBarHidden {
            isInitialStatusBarHidden = isStatusBarHiddenWhenAppear
            isFirstToUpdateStatusForStatusBar = false
        }
        if isStatusBarHiddenWhenAppear == isInitialStatusBarHidden {
            setNeedsStatusBarUpdate()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isStatusBarHiddenWhenAppear != isInitialStatusBarHidden {
            isStatusBarHiddenWhenAppear = isInitialStatusBarHidden
            setNeedsStatusBarUpdate()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        replaceBackBarButtonIfNeed()
    }
    
    func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        if navigationController != nil {
            if isNavigationBarHidden == hidden {
                return
            }
            navigationController?.setNavigationBarHidden(hidden, animated: animated)
        }
    }
    
    func setNeedsStatusBarUpdate() {
        UIView.animate(withDuration: 0.25, animations: {() -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    @objc
    public func backButtonClick(button: UIButton) {
        if let count = navigationController?.viewControllers.count, count > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func replaceBackBarButtonIfNeed() {
        guard let count = navigationController?.viewControllers.count, count > 1 else { return }
        addCustomBackButton()
    }
    
    func addCustomBackButton() {
        let button = UIButton(type: .custom)
//        button.setImage(R.image.xw_actionbar_back(), for: .normal)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
        button.addTarget(self, action: #selector(backButtonClick(button:)), for: .touchUpInside)
        let barButtonItem = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButtonItem
    }
}

extension ViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    override var prefersStatusBarHidden: Bool {
        if self.isFirstToUpdateStatusForStatusBar {
            return self.isInitialStatusBarHidden
        }
        return self.isStatusBarHiddenWhenAppear
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}
