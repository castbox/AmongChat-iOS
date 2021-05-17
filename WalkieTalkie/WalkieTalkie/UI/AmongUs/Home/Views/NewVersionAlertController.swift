//
//  NewVersionAlertController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class NewVersionAlertController: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .clear
    }
    
    static func show() {
        let vc = NewVersionAlertController()
        vc.showModal(in: UIApplication.topViewController())
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        hideModal(animated: true, completion: nil)
    }
    
    @IBAction func confirmButtonAction(_ sender: Any) {
        hideModal(animated: true, completion: nil)
        guard let url = URL(string: Constants.appStoreUrl), UIApplication.shared.canOpenURL(url) else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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

extension NewVersionAlertController: Modalable {
    func style() -> Modal.Style {
        return .alpha
    }
    
    func height() -> CGFloat {
        return Frame.Screen.height
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func containerCornerRadius() -> CGFloat {
        return 15
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
}
