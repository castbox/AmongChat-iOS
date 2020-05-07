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
    
    @IBOutlet weak var yearButton: UIButton!
    @IBOutlet weak var describeTitleWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var describeBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var describeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarContainer: UIImageView!
    @IBOutlet weak var avatarCenterYConstraint: NSLayoutConstraint!
    //    private let backgroundIV: UIImageView = {
    //        let iv = UIImageView()
    //        iv.image = R.image.icon_pro_persons()
    //        iv.contentMode = .scaleAspectFit
    //        return iv
    //    }()
    @IBOutlet weak var iapTipsLabel: UILabel!
    private var shouldStartAnimation = true
    
    private weak var selectedButton: UIButton? {
        didSet {
            oldValue?.borderColor = UIColor.white.alpha(0.6)
            oldValue?.backgroundColor = "FFAB77".color()
            
            selectedButton?.borderColor = UIColor.white.alpha(0.9)
            selectedButton?.backgroundColor = "FFD164".color()
        }
    }
    var selectedProductId: String = IAP.productYear {
        didSet {
            if FireStore.shared.isInReviewSubject.value, selectedProductId == IAP.productYear {
                iapTipsLabel.text = R.string.localizable.premiumTryTitleDes()
            } else {
                iapTipsLabel.text = nil
            }
        }
    }
    
    var closeHandler: () -> Void = { }
    
    var policyHandler: () -> Void = { }
    
    var buyProductHandler: (String) -> Void = { _ in }
    let bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //        avatarContainer.addSubview(backgroundIV)
    
        if Frame.Height.deviceDiagonalIsMinThan5_8 {
            let titleBottomEdge = Frame.Scale.height(28)
            let describeTopEdge = Frame.Scale.height(25)
            
            describeTitleWidthConstraint.constant = Frame.Scale.width(300)
            describeTopConstraint.constant = describeTopEdge
            titleBottomConstraint.constant = titleBottomEdge
        }
        var avatarContainerHeight: CGFloat {
            var height = Frame.Screen.height - 582 - Frame.Height.safeAeraBottomHeight - Frame.Height.safeAeraTopHeight
            if height > 178 {
                height = 178
            }
            if Frame.Height.deviceDiagonalIsMinThan5_5 {
                avatarContainer.isHidden = true
//                height *= 0.8
            }
            if Frame.Height.deviceDiagonalIsMinThan4_7 {
                height = 0
            }
            return height
        }
        avatarContainerHeightConstraint.constant = avatarContainerHeight
        
        selectedButton = yearButton
        selectedProductId = IAP.productYear
        
        FireStore.shared.isInReviewSubject
            .observeOn(MainScheduler.asyncInstance)
            .filter { !$0 }
            .map { !$0 }
            .bind(to: self.iapTipsLabel.rx.isHidden)
            .disposed(by: bag)
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
    
    @IBAction func yearButtonAction(_ sender: UIButton) {
        selectedButton = sender
        selectedProductId = IAP.productYear
    }
    
    @IBAction func lifetimeAction(_ sender: UIButton) {
        selectedButton = sender
        selectedProductId = IAP.productLifeTime
    }
    
    @IBAction func monthButtonAction(_ sender: UIButton) {
//        buyProductHandler(IAP.productMonth)
        selectedButton = sender
        selectedProductId = IAP.productMonth
    }
 
    func updateselectedButtonStyle() {
        
    }
}
