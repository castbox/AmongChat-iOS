//
//  NativeFeedsAdView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 15/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import MoPubSDK

class NativeFeedsAdView: XibLoadableView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var callToActionLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var sponsoredByLabel: UILabel!
    @IBOutlet weak var privacyInformationIconImageView: UIImageView!
    
    // IBInspectable
    @IBInspectable var nibName: String? = "NativeFeedsAdView"
    
    // Content View
    private(set) var contentView: UIView? = nil
    
    // MARK: - Initialization
    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupNib()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        setupNib()
//    }
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupNib()
//    }
    
    /**
     The function is essential for supporting flexible width. The native view content might be
     stretched, cut, or have undesired padding if the height is not estimated properly.
     */
    static func estimatedViewHeightForWidth(_ width: CGFloat) -> CGFloat {
        return Frame.Screen.height - Frame.Height.bottomBar
    }
    
//    func setupNib() -> Void {
//        guard let view = loadViewFromNib(nibName: nibName) else {
//            return
//        }
//
//        // Accessibility
//        mainImageView.accessibilityIdentifier = AccessibilityIdentifier.nativeAdImageView
//
//        // Size the nib's view to the container and add it as a subview.
//        view.frame = bounds
//        if #available(iOS 13.0, *) {
//            view.backgroundColor = .systemBackground
//        }
//        addSubview(view)
//        contentView = view
//
//        // Pin the anchors of the content view to the view.
//        let viewConstraints = [view.topAnchor.constraint(equalTo: topAnchor),
//                               view.bottomAnchor.constraint(equalTo: bottomAnchor),
//                               view.leadingAnchor.constraint(equalTo: leadingAnchor),
//                               view.trailingAnchor.constraint(equalTo: trailingAnchor)]
//        NSLayoutConstraint.activate(viewConstraints)
//    }
    
//    override func prepareForInterfaceBuilder() {
//        super.prepareForInterfaceBuilder()
//        setupNib()
//        contentView?.prepareForInterfaceBuilder()
//    }
}

extension NativeFeedsAdView: MPNativeAdRendering {
    // MARK: - MPNativeAdRendering
    
    func nativeTitleTextLabel() -> UILabel! {
        return titleLabel
    }
    
    func nativeMainTextLabel() -> UILabel! {
        return mainTextLabel
    }
    
    func nativeCallToActionTextLabel() -> UILabel! {
        return callToActionLabel
    }
    
    func nativeIconImageView() -> UIImageView! {
        return iconImageView
    }
    
    func nativeMainImageView() -> UIImageView! {
        return mainImageView
    }
    
    func nativeSponsoredByCompanyTextLabel() -> UILabel! {
        return sponsoredByLabel
    }
    
    func nativePrivacyInformationIconImageView() -> UIImageView! {
        return privacyInformationIconImageView
    }
    
    static func localizedSponsoredByText(withSponsorName sponsorName: String!) -> String! {
        return "Brought to you by \(sponsorName!)"
    }

    func clickableViews() -> [UIView]! {
        return [titleLabel, mainTextLabel, callToActionLabel, iconImageView, mainImageView, sponsoredByLabel, privacyInformationIconImageView]
    }
}
