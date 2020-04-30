//
//  SettingViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import StoreKit

class SettingViewController: ViewController {

    @IBOutlet weak var versionLabel: UILabel!
    
    override var screenName: Logger.Screen.Node.Start {
        return .settings
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = R.string.localizable.settingsTitle()
        versionLabel.text = "version: \(Config.appVersionWithBuildVersion)"
    }
    
    @IBAction func policyAction(_ sender: Any) {
        open(urlSting: "https://walkietalkie.live/policy.html")
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class SettingContainerTableController: UITableViewController {
    
    @IBOutlet weak var proCell: UITableViewCell!
    @IBOutlet weak var diamondsIcon: UIImageView!
    @IBOutlet weak var diamondsNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       updateSubviewStyle()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 2 {
          //rate us
            rateApp()
        } else if indexPath.row == 0 {
            guard !Settings.shared.isProValue.value,
                let premiun = R.storyboard.main.premiumViewController() else {
                return
            }
            premiun.source = .setting
            premiun.dismissHandler = { [weak self] in
                self?.updateSubviewStyle()
                premiun.dismiss(animated: true, completion: nil)
            }
            premiun.modalPresentationStyle = .fullScreen
            present(premiun, animated: true, completion: nil)
            Logger.UserAction.log(.update_pro, "settings")
        }
    }
    
    func updateSubviewStyle() {
        if Settings.shared.isProValue.value {
            proCell.backgroundColor = UIColor(hex: 0x545454)
            diamondsIcon.image = R.image.icon_setting_diamonds()
            diamondsNameLabel.text = "Walkie Talkie PRO"
        } else {
            proCell.backgroundColor = UIColor(hex: 0xFFD52E)
            diamondsIcon.image = R.image.icon_setting_diamonds_u()
        }
    }
    
    func rateApp() {

        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            let appID = "1505959099"
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


