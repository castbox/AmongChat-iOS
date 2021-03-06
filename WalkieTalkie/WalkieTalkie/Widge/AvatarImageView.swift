//
//  AvatarImageView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

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
    
    lazy var verifyIV: UIImageView = {
        let iv = UIImageView(image: R.image.iconVerifyGrayBorder())
        iv.isHidden = true
        return iv
    }()
    
    var isVerify: Bool? {
        didSet {
            verifyIV.isHidden = !(isVerify ?? false)
        }
    }
    
//    var verifyIconStyle: VerifyIconStyle = .gray
    
    static var placeholder: UIImage?
    
    var image: UIImage? {
        set { avatarIV.image = newValue }
        get { avatarIV.image }
    }
    
    var verifyStyle: VerifyIconStyle {
        didSet {
            setVerifyIcon(style: verifyStyle)
        }
    }
    
    private let avatarUrlRelay = BehaviorRelay<String?>(value: nil)
        
    var imageOb: Observable<UIImage> {
        return avatarUrlRelay.flatMap { (url) -> Observable<UIImage> in
            guard let url = url?.url else {
                return Observable.empty()
            }
            return KingfisherManager.shared.retrieveImageObservable(with: url)
        }
    }
    
    init(_ verifyStyle: VerifyIconStyle = .black) {
        self.verifyStyle = verifyStyle
        super.init(frame: .zero)
        backgroundColor = .clear
        configureSubview()
    }
    
    required init?(coder: NSCoder) {
        self.verifyStyle = .black
        super.init(coder: coder)
        configureSubview()
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
        avatarUrlRelay.accept(profile.pictureUrl)
    }
 
    func setAvatarImage(with urlString: String?) {
        avatarIV.setImage(with: urlString, placeholder: R.image.ac_profile_avatar())
        avatarUrlRelay.accept(urlString)
    }
    
    func setVerifyIcon(style: VerifyIconStyle) {
//        self.verifyIconStyle = verifyIconStyle
        verifyIV.image = style == .gray ? R.image.iconVerifyGrayBorder() : R.image.iconVerifyBlackBorder()
    }
    
    func configureSubview() {
        addSubviews(views: avatarIV, verifyIV)
        avatarIV.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        setVerifyIcon(style: verifyStyle)
        verifyIV.snp.makeConstraints { maker in
            maker.top.equalTo(-2)
            maker.trailing.equalTo(7.5)
        }
    }
}
