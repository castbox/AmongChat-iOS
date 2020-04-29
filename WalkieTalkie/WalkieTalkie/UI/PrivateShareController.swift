//
//  PrivateShareController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class PrivateShareController: ViewController {

    @IBOutlet weak var bottomEdgeConstraint: NSLayoutConstraint!
    @IBOutlet weak var passcodeLabel: UILabel!
    
    var channelName: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Logger.PageShow.log(.secret_channel_share_pop_imp)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Logger.PageShow.log(.secret_channel_share_pop_close)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        bottomEdgeConstraint.constant = Frame.Height.safeAeraBottomHeight
        passcodeLabel.text = channelName?.publicName
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        shareChannel(name: channelName) { [weak self] in
            self?.hideModal()
        }
        Logger.UserAction.log(.share_secret_channel_create, channelName)
    }
}

extension PrivateShareController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 285 + Frame.Height.safeAeraBottomHeight
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
}
