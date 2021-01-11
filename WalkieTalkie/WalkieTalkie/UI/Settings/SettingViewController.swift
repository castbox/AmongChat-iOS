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

class SettingViewController: ViewController {
    
    private typealias Language = Entity.GlobalSetting.KeyValue
    
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
        logoutFooter.frame = CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width, height: 90))
        tb.tableFooterView = logoutFooter
        return tb
    }()
    
    private lazy var logoutFooter: UIView = {
        let v = UIView()
        v.addSubview(logoutBtn)
        logoutBtn.snp.makeConstraints { (make) in
            make.left.equalTo(40)
            make.right.equalTo(-40)
            make.height.equalTo(50)
            make.top.equalToSuperview().offset(28)
        }
        return v
    }()
    
    private lazy var settingOptions: [Option] = generateDataSource() {
        didSet {
            settingsTable.reloadData()
        }
    }
    
    override var screenName: Logger.Screen.Node.Start {
        return .settings
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupEvent()
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
                Logger.Action.log(.login_success)
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
        cdPrint("among chat")
        let isReleaseMode = Defaults[\.isReleaseMode]
        Defaults[\.isReleaseMode] = !isReleaseMode
        exit(0)
    }

}

extension SettingViewController {
    
    private func showSystemNavigationBar() {
        isNavigationBarHiddenWhenAppear = false
        self.navigationController?.navigationBar.setColors(background: UIColor.theme(.backgroundBlack), text: .white)
        self.navigationController?.navigationBar.setTitleFont(R.font.nunitoExtraBold(size: 24) ?? .systemFont(ofSize: 24, weight: .medium), color: .white)
        self.customBackButton.setImage(R.image.ac_back(), for: .normal)
    }
    
    private func setupLayout() {

        view.backgroundColor = UIColor.theme(.backgroundBlack)
        
        showSystemNavigationBar()
        
        self.title = R.string.localizable.settingsTitle()
        versionLabel.text = "version: \(Config.appVersionWithBuildVersion)"
        
        view.addSubviews(views: settingsTable, logoIV, versionLabel, policyLabel)
        
        settingsTable.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        logoIV.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-90)
        }
        
        versionLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(logoIV.snp.bottom).offset(8)
        }
        
        policyLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(versionLabel.snp.bottom).offset(8)
        }
        
    }
    
    func setupEvent() {
        
        Observable.combineLatest(Settings.shared.isProValue.replay(),
                                 Settings.shared.preferredChatLanguage.replay(),
                                 ChatLanguageHelper.supportedLanguages)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _, _, lans in
                guard let `self` = self else { return }
                self.settingOptions = self.generateDataSource(languages: lans)
            })
            .disposed(by: bag)
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
    
    private func upgradePro() {
        guard !Settings.shared.isProValue.value,
              let premiun = R.storyboard.main.premiumViewController() else {
            return
        }
        premiun.style = .likeGuide
        premiun.source = .setting
        premiun.dismissHandler = {
            premiun.dismiss(animated: true, completion: nil)
        }
        premiun.modalPresentationStyle = .fullScreen
        present(premiun, animated: true, completion: nil)
        Logger.UserAction.log(.update_pro, "settings")
    }
    
    private func rateApp() {//rate us
        view.raft.autoShow(.loading)
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            let appID = Constants.appId
            //            let urlStr = "https://itunes.apple.com/app/id\(appID)" // (Option 1) Open App Page
            let urlStr = "https://itunes.apple.com/app/id\(appID)?action=write-review" // (Option 2) Open App Review Page
            
            guard let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) else { return }
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url) // openURL(_:) is deprecated from iOS 10.
            }
        }
    }
    
    private func generateDataSource(languages: [Language] = []) -> [Option] {
        var options: [Option] = [
            Option(type: .rateUs, selectionHandler: { [weak self] in
                self?.rateApp()
            }),
            Option(type: .shareApp, selectionHandler: { [weak self] in
                self?.shareApp()
            }),
        ]
        
        if Settings.shared.isInReview.value || Settings.shared.isProValue.value {
            options.append(
                Option(type: .premium, selectionHandler: { [weak self] in
                    self?.upgradePro()
                })
            )
        }
        
        if languages.count > 0 {
            
            let currentLan = ChatLanguageHelper.currentLanguage(from: languages)
            
            let regionOption = Option(type: .region, rightText: currentLan.value, selectionHandler: { [weak self] in
                let vc = AmongChat.ChatLanguageViewController(with: languages)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            options.insert(regionOption, at: 0)
        }
        
        return options
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
            case premium
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
            case .premium:
                if Settings.shared.isProValue.value {
                    return R.string.localizable.profilePro()// "PRO"
                } else {
                    return R.string.localizable.profileUnlockPro()// "Unlock PRO"
                }
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
            case .premium:
                return R.image.ac_setting_diamonds()
            }
        }
        
        var rightIcon: UIImage? {
            switch type {
            case .premium:
                if Settings.shared.isProValue.value {
                    return nil
                } else {
                    return R.image.ac_right_arrow()
                }
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
                maker.left.equalTo(20)
                maker.centerY.equalToSuperview()
            }
            
            leftLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(leftIcon.snp.right).offset(12)
                maker.right.lessThanOrEqualTo(rightLabel.snp.left).offset(-8)
            }
            
            rightLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.right.equalTo(rightIcon.snp.left).offset(-8)
            }
            
            rightIcon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(20)
                maker.right.equalToSuperview().inset(20)
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
