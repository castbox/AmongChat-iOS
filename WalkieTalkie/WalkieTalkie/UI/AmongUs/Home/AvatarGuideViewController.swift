//
//  AvatarGuideViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 27/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AvatarGuideViewController: ViewController {
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var leftImageView: UIImageView!
    @IBOutlet private weak var rightImageView: UIImageView!
    @IBOutlet private weak var goButton: UIButton!
    
    var goHandler: CallBack?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        // Do any additional setup after loading the view.
        
        //
        goButton.setTitle(R.string.localizable.bigGo().uppercased(), for: .normal)
        //
        leftImageView.setImage(with: "https://s3.among.chat/static/avatar/LA0031.png")
        rightImageView.setImage(with: "https://s3.among.chat/static/avatar/LA0031.png")
    }

    @IBAction func closeButtonAction(_ sender: Any) {
        dismissModal()
    }
    
    @IBAction func goButtonAction(_ sender: Any) {
        dismissModal(animated: true) { [weak self] in
            self?.goHandler?()
        }
    }
}

extension AvatarGuideViewController: Modalable {
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
