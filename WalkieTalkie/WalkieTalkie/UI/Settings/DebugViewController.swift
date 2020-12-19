//
//  DebugViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
