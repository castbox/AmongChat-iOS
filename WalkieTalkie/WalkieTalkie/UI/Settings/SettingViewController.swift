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

class SettingViewController: ViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    override var screenName: Logger.Screen.Node.Start {
        return .settings
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showSystemNavigationBar()
        
        view.backgroundColor = UIColor.theme(.backgroundBlack)
        
        self.title = R.string.localizable.settingsTitle()
        versionLabel.text = "version: \(Config.appVersionWithBuildVersion)"
    }
    
    @IBAction func policyAction(_ sender: Any) {
        open(urlSting: Config.PolicyType.url(.policy))
    }
    
    @IBAction func termsAction(_ sender: Any) {
        open(urlSting: Config.PolicyType.url(.terms))
    }
    
    @IBAction func updateEnvironment(_ sender: Any) {
        cdPrint("among chat")
        let isReleaseMode = Defaults[\.isReleaseMode]
        Defaults[\.isReleaseMode] = !isReleaseMode
        exit(0)
    }
    
    private func showSystemNavigationBar() {
        isNavigationBarHiddenWhenAppear = false
        self.navigationController?.navigationBar.setColors(background: UIColor.theme(.backgroundBlack), text: .white)
        self.navigationController?.navigationBar.setTitleFont(R.font.nunitoExtraBold(size: 24) ?? .systemFont(ofSize: 24, weight: .medium), color: .white)
        self.customBackButton.setImage(R.image.ac_back(), for: .normal)
    }
}

class SettingContainerTableController: UITableViewController {
    
    let bag = DisposeBag()
    private var showVipPro = true {
        didSet {
            tableView.reloadData()
        }
    }
    
    @IBOutlet weak var diamondsNameLabel: UILabel!
    @IBOutlet weak var diamondArrowView: UIImageView!
    @IBOutlet weak var logotButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.theme(.backgroundBlack)
        
        showVipPro = FireStore.shared.isInReviewSubject.value || Settings.shared.isProValue.value
        updateSubviewStyle()
    }
    
    @IBAction func logout(_ sender: Any) {
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
                (UIApplication.shared.delegate as! AppDelegate).setupInitialView()
            }).disposed(by: bag)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showVipPro {
            return 3
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            rateApp()
        } else if indexPath.row == 1 {
            shareApp()
        }
        else if indexPath.row == 2 {
            upgradePro()
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
    
    
    private func upgradePro() {
        guard !Settings.shared.isProValue.value,
              let premiun = R.storyboard.main.premiumViewController() else {
            return
        }
        premiun.style = .likeGuide
        premiun.source = .setting
        premiun.dismissHandler = { [weak self] in
            self?.updateSubviewStyle()
            premiun.dismiss(animated: true, completion: nil)
        }
        premiun.modalPresentationStyle = .fullScreen
        present(premiun, animated: true, completion: nil)
        Logger.UserAction.log(.update_pro, "settings")
    }
    
    private func updateSubviewStyle() {
        
        if Settings.shared.isProValue.value {
            diamondsNameLabel.text = R.string.localizable.profilePro()// "PRO"
            diamondArrowView.isHidden = true
        } else {
            diamondsNameLabel.text = R.string.localizable.profileUnlockPro()// "Unlock PRO"
        }
        logotButton.snp.makeConstraints { (make) in
            make.left.equalTo(40)
            make.right.equalTo(-40)
            make.height.equalTo(50)
            make.bottom.equalToSuperview()
        }
    }
    
    private func rateApp() {//rate us
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
}
