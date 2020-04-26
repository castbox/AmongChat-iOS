//
//  GuideThirdView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GuideThirdView: XibLoadableView, PremiumContainerable {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var avatarContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var skipButtonButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var describeTitleWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var describeBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var describeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarContainer: UIImageView!
    //    private let backgroundIV: UIImageView = {
    //        let iv = UIImageView()
    //        iv.image = R.image.icon_pro_persons()
    //        iv.contentMode = .scaleAspectFit
    //        return iv
    //    }()
    private var shouldStartAnimation = true
    
    var closeHandler: () -> Void = { }
    
    var policyHandler: () -> Void = { }
    
    var buyProductHandler: (String) -> Void = { _ in }
    let bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //        avatarContainer.addSubview(backgroundIV)
    
//        scrollView.contentInset = .zero
        if Frame.Height.deviceDiagonalIsMinThan5_8 {
            let titleBottomEdge = Frame.Scale.height(28)
            let describeTopEdge = Frame.Scale.height(25)
//            let describeBottomEdge = Frame.Scale.height(36)
            describeTitleWidthConstraint.constant = Frame.Scale.width(300)
            describeTopConstraint.constant = describeTopEdge
//            describeBottomConstraint.constant = describeBottomEdge
            titleBottomConstraint.constant = titleBottomEdge
        }
        var avatarContainerHeight: CGFloat {
            var height = Frame.Screen.height - 497 - Frame.Height.safeAeraBottomHeight - Frame.Height.safeAeraTopHeight
            if height > 246 {
                height = 246
            }
            return height
        }
        avatarContainerHeightConstraint.constant = avatarContainerHeight
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //    func startAnimation() {
    //        guard shouldStartAnimation else {
    //            return
    //        }
    //        shouldStartAnimation = false
    //        let width = backgroundIV.image?.size.width ?? 3800
    //        UIView.beginAnimations(nil, context: nil)
    //        UIView.setAnimationDuration(100)
    //        UIView.setAnimationCurve(.linear)
    //        UIView.setAnimationRepeatCount(HUGE)
    //        UIView.setAnimationRepeatAutoreverses(true)
    //        UIView.setAnimationBeginsFromCurrentState(true)
    //        backgroundIV.frame = CGRect(x: 0, y: 0, width: width, height: 60)
    //        UIView.commitAnimations()
    //    }
    
    
    
    @IBAction func closeButtonAction(_ sender: Any) {
        closeHandler()
    }
    
    @IBAction func policyAction(_ sender: Any) {
        policyHandler()
    }
    
    @IBAction func policyButtonAction(_ sender: Any) {
        policyHandler()
        //        open(urlSting: "https://walkietalkie.live/policy.html")
    }
    
    @IBAction func lifetimeAction(_ sender: Any) {
        
        buyProductHandler(IAP.productLifeTime)
    }
    
    @IBAction func monthButtonAction(_ sender: Any) {
        buyProductHandler(IAP.productMonth)
    }
    
    @IBAction func skipTrialAction(_ sender: Any) {
        buyProductHandler(IAP.productYear)
    }
}
