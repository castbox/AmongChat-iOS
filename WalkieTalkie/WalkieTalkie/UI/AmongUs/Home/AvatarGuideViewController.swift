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
    
    private let avatarList: [String]
    var goHandler: CallBack?
    
    init(_ avatarList: [String]) {
        self.avatarList = avatarList
        super.init(nibName: "AvatarGuideViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        // Do any additional setup after loading the view.
        
        goButton.setTitle(R.string.localizable.bigGo().uppercased(), for: .normal)
    
        leftImageView.setImage(with: avatarList.safe(0), placeholder: R.image.ac_profile_avatar())
        rightImageView.setImage(with: avatarList.safe(1), placeholder: R.image.ac_profile_avatar())
    
        if avatarList.count == 1 {
            stackView.removeArrangedSubview(rightImageView)
            rightImageView.removeFromSuperview()
        }
        Logger.Action.log(.new_avatar_dialog_imp)
    }

    @IBAction func closeButtonAction(_ sender: Any) {
        dismissModal()
    }
    
    @IBAction func goButtonAction(_ sender: Any) {
        Logger.Action.log(.new_avatar_dialog_clk, category: .go)
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
