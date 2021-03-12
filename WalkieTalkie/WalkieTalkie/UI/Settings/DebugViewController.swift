//
//  DebugViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import MessageUI
import CastboxDebuger

class DebugViewController: ViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        textView.text = Constants.deviceInfo().map { (key, value) -> String in
            return key + ": \(value)"
        }.joined(separator: "\n")
        .appending("\n")
        .appending("fcmToken: \(FireMessaging.shared.fcmToken ?? "") \n")
    }
    
    @IBAction func exportLogger(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setSubject("Feedback - Cuddle iOS" + "(\(Config.appVersion))" + "isProV: \(Settings.shared.isProValue.value)")
            controller.setToRecipients(["shichong.yuan@castbox.fm"])
            controller.mailComposeDelegate = self
            if let fileURL = Debug.zip() {
                do {
                    let data = try Data(contentsOf: fileURL)
                    controller.addAttachmentData(data, mimeType: "application/zip", fileName: Debug.filename)
                } catch {
                    
                }
            }
//            if let body = self.feedbackInfo() {
//                controller.setMessageBody(body, isHTML: false)
//            }
            self.present(controller, animated: true, completion: nil)
            return
        } else {
            if let openURL = URL(string: "mailto:contact@cuddlelive.com") {
                UIApplication.shared.open(openURL)
            }
        }
    }
    
//    func feedbackInfo() -> String? {
//        guard let app = Network.app(),
//            let user = Network.user(),
//            let device = Network.device() else { return nil }
//
////        let premium = Knife.IAP.shared.isPremium ? " (premium)": ""
//        let premium = ""
//        let fcmToken = FireMessaging.shared.fcmToken ?? ""
//        let country = { () -> String? in
//            if let code = Constant.countryCode {
//                let locale = Locale(identifier: "en")
//                return locale.localizedString(forRegionCode: code)
//            }
//            return nil
//            }() ?? "unknown"
//
//        var info = "App: " + app.version + " (" + Constant.buildVersion + ")" +
//            " - " + " iOS \(UIDevice.current.systemVersion)" +
//            " - " + Constant.hardwareName + " (" + Constant.hardwareCode + ") " + "\n"
//
//        info += "User: " + user.uid + premium +
//            " - " + country + "\n"
//
//        info += "Device: " + device.id + " (" + fcmToken + ") " + "\n"
//
//        info += "----------\n\n\n\n"
//        return info
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DebugViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.presentingViewController?.dismiss(animated: true, completion: nil)
//        switch result {
//        case .sent:
//            Toast.showToast(alertType: .operationComplete, message: NSLocalizedString("toast.email.sent", comment: ""))
//        case .cancelled:
//            Toast.showToast(alertType: .operationComplete, message: NSLocalizedString("toast.email.canceled.deleted", comment: ""))
//        case .saved:
//            Toast.showToast(alertType: .warnning, message: NSLocalizedString("toast.email.saved.draft", comment: ""))
//        case .failed:
//            Toast.showToast(alertType: .warnning, message: NSLocalizedString("toast.email.failed", comment: ""))
//        }
    }
}
