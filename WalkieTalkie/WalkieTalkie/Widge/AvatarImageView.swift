//
//  AvatarImageView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit

class AvatarImageView: UIView {
    
    enum VerifyIconStyle {
        case gray
        case black
    }
    
    private lazy var avatarIV: UIImageView = {
        let iv = UIImageView(image: R.image.ac_profile_avatar())
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    private lazy var verifyIV: UIImageView = {
        let iv = UIImageView(image: R.image.iconVerifyGrayBorder())
        iv.isHidden = true
        return iv
    }()
    
    var isVerify: Bool? {
        didSet {
            verifyIV.isHidden = !(isVerify ?? false)
        }
    }
    
//    var verifyIconStyle: VerifyIconStyle {
//        didSet {
//            verifyIconStyle == .gray ? R.image.iconVerifyGrayBorder() : R.image.iconVerifyBlackBorder()
//        }
//    }
    
    static var placeholder: UIImage?
    
    var image: UIImage? {
        set { avatarIV.image = newValue }
        get { avatarIV.image }
    }
    
    init(_ verifyStyle: VerifyIconStyle = .gray) {
//        self.verifyIconStyle = verifyStyle
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubviews(views: avatarIV, verifyIV)
        avatarIV.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
//        verifyIconStyle = verifyStyle
        verifyIV.image = verifyStyle == .gray ? R.image.iconVerifyGrayBorder() : R.image.iconVerifyBlackBorder()
        verifyIV.snp.makeConstraints { maker in
            maker.top.equalTo(-1)
            maker.trailing.equalTo(7.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarIV.cornerRadius = avatarIV.bounds.width / 2
    }
    
    func updateAvatar(with profile: Entity.UserProfile) {
        
        let placeholder: UIImage?
        
        if profile.uid.isSelfUid {
            placeholder = Self.placeholder ?? R.image.ac_profile_avatar()
        } else {
            placeholder = R.image.ac_profile_avatar()
        }
        
        avatarIV.setImage(with: profile.pictureUrl, placeholder: placeholder)
    }
 
    func setAvatarImage(with urlString: String?) {
        avatarIV.setImage(with: urlString, placeholder: R.image.ac_profile_avatar())
    }
}
