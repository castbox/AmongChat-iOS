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
import SCSDKCreativeKit
import SwifterSwift

class ViewController: UIViewController, ScreenLifeLogable, JoinRoomable {
    
    var isRequestingRoom: Bool = false
    
    var isNavigationBarHiddenWhenAppear = false {
        didSet {
            if isNavigationBarHiddenWhenAppear {
                if #available(iOS 11.0, *) {
                    
                } else {
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
    var statusBarStyle: UIStatusBarStyle = .default
    
    /**
     是否为第一次设置 statusBar hidden 的值
     如果是第一次, 则会更新 initialStatusBarHidden 的值
     并且再次调用 setNeedsStatusBarAppearanceUpdate
     来达到平滑的隐藏或者显示statusBar的目的
     */
    private var isFirstToUpdateStatusForStatusBar: Bool = true
    
    let bag = DisposeBag()
    
    var screenLifeStartTime: Date = .init()
    
    fileprivate lazy var snapAPI = {
        return SCSDKSnapAPI()
    }()
    
    var screenName: Logger.Screen.Node.Start {
        return .ios_ignore
    }
    
    var contentScrollView: UIScrollView? {
        nil
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = isHidesBottomBarWhenPushed
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.hidesBottomBarWhenPushed = isHidesBottomBarWhenPushed
    }
    
    deinit {
        debugPrint("[VIEWCONTROLLER-DEINIT-\(NSStringFromClass(type(of: self)))]")
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
        
//        AdsManager.shared.requestRewardVideoIfNeed()
        screenLifeStartTime = Date()
        loggerScreenShow()
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
        logScreenDurationIfNeed()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hexString: "#121212")

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
    
    lazy var customBackButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(R.image.backNor(), for: .normal)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
        button.addTarget(self, action: #selector(backButtonClick(button:)), for: .touchUpInside)
        return button
    }()
    
    func addCustomBackButton() {
        let barButtonItem = UIBarButtonItem(customView: customBackButton)
        self.navigationItem.leftBarButtonItem = barButtonItem
    }
    
    func addErrorView(_ retryAction: (() -> Void)? = nil) {
        let v = AmongChat.Home.LoadErrorView()
        self.view.addSubview(v)
        v.snp.makeConstraints { (maker) in
            maker.top.equalTo(Frame.Height.navigation)
            maker.left.right.bottom.equalToSuperview()
        }
        v.showUp { [weak v] in
            v?.removeFromSuperview()
            retryAction?()
        }
    }
    
    func addNoDataView(_ message: String, image: UIImage? = nil) {
        removeNoDataView()
        let v = NoDataView(with: message, image: image)
        view.addSubview(v)
        v.snp.makeConstraints { (maker) in
            maker.top.equalTo(Frame.Height.navigation)
            maker.left.right.bottom.equalToSuperview()
        }
    }
    
    func removeNoDataView() {
        view.subviews
            .first { $0 is NoDataView }?
            .removeFromSuperview()
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

extension ViewController {
    
    func logScreenDurationIfNeed() {
        guard screenName != .ios_ignore else {
            return
        }
        loggerScreenDuration()
    }
}

extension ViewController {
    func showReportSheet() {
        let vc = Social.ReportViewController()
        vc.showModal(in: self)
        vc.selectedReason = {[weak self] (reason) in
            self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
        }
    }
}

class ActivityViewCustomActivity: UIActivity {

    var customActivityType = ""
    var activityName = ""
    var iconImage: UIImage?
    var customActionWhenTapped: (() -> Void)?

    init(title: String, image: UIImage?, performAction: (() -> ())?) {
        self.activityName = title
        self.iconImage = image
        self.customActivityType = "Action \(title)"
        self.customActionWhenTapped = performAction
        super.init()
    }
    
    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType(rawValue: "live.walkietalkie.snapchat.activity")
    }

    override class var activityCategory: UIActivity.Category {
        .share
    }
    
    override var activityTitle: String? {
        activityName
    }

    override var activityImage: UIImage? {
        iconImage
    }
    
    @objc var _activitySettingsImage: UIImage? {
        return iconImage?.withRoundedCorners(radius: 10)?.scaled(toWidth: 29)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        // nothing to prepare
    }

    override var activityViewController: UIViewController? {
        nil
    }

    override func perform() {
        customActionWhenTapped?()
        activityDidFinish(true)
    }
}
