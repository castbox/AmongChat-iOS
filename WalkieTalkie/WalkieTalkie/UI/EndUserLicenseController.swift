//
//  EndUserLicenseController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/7/21.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class EndUserLicenseController: ViewController {
    @IBOutlet weak var textView: UITextView!
    var isScroll: Bool = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.isNavigationBarHiddenWhenAppear = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.setContentOffset(.zero, animated: false)
    }

    @IBAction func confirmButtonAction(_ sender: Any) {
        hideModal()
    }
}

extension EndUserLicenseController: Modalable {
    
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
