//
//  SettingViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import StoreKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SCSDKLoginKit
import MessageUI
import CastboxDebuger

class SettingViewController: ViewController {
    
    private typealias Language = Entity.GlobalSetting.KeyValue
    
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
        lb.text = R.string.localizable.settingsTitle()
        return n
    }()
    
    private lazy var versionLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 12)
        lb.textColor = UIColor(hex6: 0xFFFFFF)
        return lb
    }()
    
    private lazy var policyLabel: PolicyLabel = {
        let terms = R.string.localizable.amongChatSettingTerms()
        let privacy = R.string.localizable.amongChatSettingPrivacy()
        let text = "\(terms) & \(privacy)"
        let lb = PolicyLabel(with: text, privacy: privacy, terms: terms)
        lb.onInteration = { [weak self] targetPath in
            self?.open(urlSting: targetPath)
        }
        return lb
    }()
    
    private lazy var logoIV: UIImageView = {
        let i = UIImageView(image: R.image.ac_home_banner())
        i.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(updateEnvironment(_:)))
        tap.numberOfTapsRequired = 5
        i.addGestureRecognizer(tap)
        return i
    }()
    
    private lazy var logoutBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 25
        btn.layer.masksToBounds = true
        btn.backgroundColor = UIColor(hex6: 0x232323)
        btn.addTarget(self, action: #selector(onLogoutBtn), for: .primaryActionTriggered)
        btn.setTitle(R.string.localizable.logOut(), for: .normal)
        btn.setTitleColor(UIColor(hex6: 0xFFFFFF), for: .normal)
        btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
        return btn
    }()
    
    private lazy var settingsTable: UITableView = {
        let tb = UITableView(frame: .zero, style: .plain)
        tb.showsVerticalScrollIndicator = false
        tb.register(SettingCell.self, forCellReuseIdentifier: NSStringFromClass(SettingCell.self))
        tb.backgroundColor = UIColor.theme(.backgroundBlack)
        tb.dataSource = self
        tb.delegate = self
        tb.separatorStyle = .none
        tb.rowHeight = 73
        return tb
    }()
    
    private let minimumFooterHeight: CGFloat = 240
    
    private lazy var tableFooter: UIView = {
        let v = UIView()
        v.addSubviews(views: logoutBtn, logoIV, versionLabel, policyLabel)
        
        logoutBtn.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(40)
            make.height.equalTo(50)
            make.top.equalToSuperview().offset(28)
        }
        
        logoIV.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-90)
        }
        
        versionLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(logoIV.snp.bottom).offset(8)
        }
        
        policyLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(versionLabel.snp.bottom).offset(8)
        }
        v.frame = CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width, height: minimumFooterHeight))
        return v
    }()
    
    private lazy var settingOptions: [Option] = generateDataSource() {
        didSet {
            settingsTable.reloadData()
        }
    }
    
    private lazy var cacheManager = CacheManager()
    
    override var screenName: Logger.Screen.Node.Start {
        return .settings
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupEvent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableFooterHeight()
    }
}

extension SettingViewController {
    // MARK: - UIAction
    
    @objc
    private func onLogoutBtn() {
        Logger.Action.log(.logout_clk)
        let removeBlock = view.raft.show(.loading)
        Request.logout().asObservable()
            .observeOn(MainScheduler.instance)
            .do(onDispose: {
                removeBlock()
            })
            .subscribe(onNext: { (data) in
                Settings.shared.clearAll()
                //clear
                if SCSDKLoginClient.isUserLoggedIn {
                    SCSDKLoginClient.clearToken()
                }
                (UIApplication.shared.delegate as! AppDelegate).setupInitialView()
            }).disposed(by: bag)
    }
    
    @objc
    private func updateEnvironment(_ sender: Any) {
        //debug
        Settings.shared.amongChatAvatarListShown.value = nil
        Settings.shared.globalSetting.value = nil
        Defaults[\.avatarGuideUpdateTime] = ""
        
        let isReleaseMode = Defaults[\.isReleaseMode]
        Defaults[\.isReleaseMode] = !isReleaseMode
        exit(0)
    }
    
}

extension SettingViewController {
    
    private func setupLayout() {
        
        view.backgroundColor = UIColor.theme(.backgroundBlack)
        
        versionLabel.text = "version: \(Config.appVersionWithBuildVersion)"
        
        view.addSubviews(views: navView, settingsTable)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        settingsTable.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(navView.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        settingsTable.tableFooterView = tableFooter
        settingsTable.reloadData()
    }
    
    private func setupEvent() {
        
        Observable.combineLatest(Settings.shared.isProValue.replay(),
                                 Settings.shared.preferredChatLanguage.replay(),
                                 ChatLanguageHelper.supportedLanguages)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _, _, lans in
                self?.generateRegionOption(languages: lans)
            })
            .disposed(by: bag)
        
        Settings.shared.loginResult.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self,
                      let _ = result else {
                    return
                }
                self.logoutBtn.isHidden = !AmongChat.Login.isLogedin
            })
            .disposed(by: bag)
        
        cacheManager.cacheFormatedSize()
            .subscribe(onSuccess: { [weak self] (formattedSize) in
                self?.updateCacheFormattedSize(formattedSize)
            })
            .disposed(by: bag)
    }
    
    private func updateCacheFormattedSize(_ formattedSize: String) {
        if let idx = settingOptions.firstIndex(where: { $0.type == .clearCache }) {
            var op = settingOptions[idx]
            op.rightText = formattedSize
            settingOptions[idx] = op
        }
    }
    
    private func shareApp() {
        Logger.Action.log(.settings_share_app_clk, category: nil)
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        
        self.view.isUserInteractionEnabled = false
        ShareManager.default.showActivity(viewController: self) { () in
            removeBlock()
        }
    }
    
    private func rateApp() {//rate us
//        view.raft.autoShow(.loading)
//        if #available(iOS 10.3, *) {
//            SKStoreReviewController.requestReview()
//        } else {
            let appID = Constants.appId
            //            let urlStr = "https://itunes.apple.com/app/id\(appID)" // (Option 1) Open App Page
            let urlStr = "https://itunes.apple.com/app/id\(appID)?action=write-review" // (Option 2) Open App Review Page
            
            guard let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) else { return }
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url) // openURL(_:) is deprecated from iOS 10.
            }
//        }
    }
    
    private func restorePurchases() {
        let removeBlock = view.raft.show(.loading)
        let completion = { [weak self] in
            self?.settingsTable.isUserInteractionEnabled = true
            removeBlock()
        }
        settingsTable.isUserInteractionEnabled = false
        
        IAP.Restore.restorePurchase { [weak self] (hasRestorable) in
            completion()
            guard hasRestorable else { return }
            self?.view.raft.autoShow(.text(R.string.localizable.premiumRestoreSucceeded()))
        }
    }
    
    private func getVerified() {
        
        guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: .applyVerified)) else {
            return
        }
        self.open(urlSting: "https://docs.google.com/forms/d/e/1FAIpQLSeTzpMgWikmqajPHbEBAstCdFVB4Xo1CjYDc29wj4zSJq99Kg/viewform")        
    }
    
    private func exportLogger() {
        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setSubject("Feedback - AmongChat iOS" + "(\(Config.appVersion))" + "isPro: \(Settings.shared.isProValue.value)")
            controller.setToRecipients(["contact@among.chat"])
            controller.mailComposeDelegate = self
            if let fileURL = Debug.zip() {
                do {
                    let data = try Data(contentsOf: fileURL)
                    controller.addAttachmentData(data, mimeType: "application/zip", fileName: Debug.filename)
                } catch {
                    
                }
            }
            self.present(controller, animated: true, completion: nil)
            return
        } else {
            if let openURL = URL(string: "mailto:contact@among.chat") {
                UIApplication.shared.open(openURL)
            }
        }
    }
    
    private func clearCacheAlert() {
        let alert = amongChatAlert(title: nil, message: R.string.localizable.amongChatClearCacheTip(), cancelTitle: R.string.localizable.toastCancel(), confirmTitle: R.string.localizable.amongChatClear(), confirmTitleColor: UIColor(hex6: 0xFB5858), confirmAction: { [weak self] in
            
            guard let `self` = self else { return }
            
            let hudRemoval = self.view.raft.show(.text(R.string.localizable.amongChatClearing()))
            
            self.cacheManager.clearCache()
                .flatMap({ (_) -> Single<String> in
                    self.cacheManager.cacheFormatedSize()
                })
                .do(onDispose: {
                    hudRemoval()
                })
                .subscribe(onSuccess: { (formattedSize) in
                    self.updateCacheFormattedSize(formattedSize)
                })
                .disposed(by: self.bag)
            
        })
        alert.present()
    }
        
    private func generateDataSource() -> [Option] {
        let options: [Option] = [
            Option(type: .blockList, selectionHandler: { [weak self] in
                let vc = Social.BlockedUserList.ViewController()
                self?.navigationController?.pushViewController(vc)
            }),
            Option(type: .community, selectionHandler: { [weak self] in
                self?.open(urlSting: Config.PolicyType.url(.guideline))
            }),
            Option(type: .rateUs, selectionHandler: { [weak self] in
                self?.rateApp()
            }),
            Option(type: .shareApp, selectionHandler: { [weak self] in
                self?.shareApp()
            }),
            Option(type: .restorePurchase, selectionHandler: { [weak self] in
                self?.restorePurchases()
            }),
            Option(type: .getVerified, selectionHandler: { [weak self] in
                self?.getVerified()
            }),
            Option(type: .clearCache, rightText: "", selectionHandler: { [weak self] in
                self?.clearCacheAlert()
            }),
            Option(type: .feedback, selectionHandler: { [weak self] in
                self?.exportLogger()
            }),
        ]
        
        return options
    }
    
    private func generateRegionOption(languages: [Language]) {
        if languages.count > 0 {
            
            let currentLan = ChatLanguageHelper.currentLanguage(from: languages)
            
            let regionOption = Option(type: .region, rightText: currentLan.value, selectionHandler: { [weak self] in
                let vc = AmongChat.ChatLanguageViewController(with: languages)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            
            if let idx = settingOptions.firstIndex(where: { $0.type == .region }) {
                settingOptions[idx] = regionOption
            } else {
                settingOptions.insert(regionOption, at: 0)
            }
        }
    }
    
    private func updateTableFooterHeight() {
        let extraHeight = settingsTable.bounds.height - settingsTable.contentSize.height
        guard extraHeight > minimumFooterHeight,
              let frame = settingsTable.tableFooterView?.frame else {
            return
        }
        settingsTable.tableFooterView?.frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: extraHeight))
        settingsTable.reloadData()
    }
}

extension SettingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(SettingCell.self), for: indexPath) as! SettingCell
        
        if let option = settingOptions.safe(indexPath.row) {
            cell.configCell(with: option)
        }
        
        return cell
    }
}

extension SettingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = settingOptions.safe(indexPath.row) else { return }
        option.selectionHandler()
    }
    
}

extension SettingViewController {
    
    struct Option {
        
        enum OptionType {
            case region
            case rateUs
            case shareApp
            case community
            case blockList
            case restorePurchase
            case getVerified
            case feedback
            case clearCache
        }
        
        let type: OptionType
        var rightText: String? = nil
        let selectionHandler: (() -> Void)
        
        var leftText: String {
            switch type {
            case .region:
                return R.string.localizable.settingChatLanguage()
            case .rateUs:
                return R.string.localizable.rateUs()
            case .shareApp:
                return R.string.localizable.shareApp()
            case .community:
                return R.string.localizable.profileCommunity()
            case .blockList:
                return R.string.localizable.profileBlockUser()
            case .restorePurchase:
                return R.string.localizable.premiumRestorePurchases()
            case .getVerified:
                return R.string.localizable.amongChatSettingGetVerified()
            case .feedback:
                return R.string.localizable.amongChatContactUs()
            case .clearCache:
                return R.string.localizable.amongChatClearCache()
            }
        }
        
        var leftIcon: UIImage? {
            switch type {
            case .region:
                return R.image.ac_setting_region()
            case .rateUs:
                return R.image.ac_rate_us()
            case .shareApp:
                return R.image.ac_share_app()
            case .community:
                return R.image.ac_profile_communtiy()
            case .blockList:
                return R.image.ac_profile_block()
            case .restorePurchase:
                return R.image.ac_restore_purchases()
            case .getVerified:
                return R.image.icon_verified_30()
            case .feedback:
                return R.image.ac_setting_feedback()
            case .clearCache:
                return R.image.ac_setting_clear_cache()
            }
        }
        
        var rightIcon: UIImage? {
            switch type {
            default:
                return R.image.ac_right_arrow()
            }
        }
        
    }
    
}

extension SettingViewController {
    
    class SettingCell: TableViewCell {
        
        private lazy var leftIcon: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var leftLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor(hex6: 0xFFFFFF)
            return lb
        }()
        
        private lazy var rightLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor(hex6: 0xFFFFFF)
            return lb
        }()
        
        private lazy var rightIcon: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            selectionStyle = .none
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: leftIcon, leftLabel, rightLabel, rightIcon)
            
            leftIcon.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(30)
                maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
            }
            
            leftLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(leftIcon.snp.trailing).offset(12)
                maker.trailing.lessThanOrEqualTo(rightLabel.snp.leading).offset(-8)
            }
            
            rightLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(rightIcon.snp.leading).offset(-8)
            }
            
            rightIcon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(20)
                maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
            }
        }
        
        func configCell(with option: Option) {
            
            leftIcon.image = option.leftIcon
            leftLabel.text = option.leftText
            rightLabel.text = option.rightText
            rightIcon.image = option.rightIcon
            
        }
        
    }
    
}

extension SettingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
