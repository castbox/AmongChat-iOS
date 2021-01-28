//
//  UserTagView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 27/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift

//class UserTagView: UIView {
//
//    private let SystemBotUid: Int = 100000
//
//    enum Style {
//        case min
//        case big
//    }
//
//    enum Tag: Int {
//        case role
//        case location
//        case gender
//        case lord
//        case vip
//        case userLevel
//        case hostLevel
//        case newbie //5级以下 新人
//        case badge
//    }
//
//    lazy var profileStackView: UIStackView = {
//        let view = UIStackView(frame: .zero)
//        view.spacing = 4
//        view.distribution = .equalSpacing
//        return view
//    }()
//
//    lazy var locationIcon: IconLabelView = {
//        let icon = IconLabelView(frame: .zero)
//        icon.margin = 3
//        icon.contentHeight = 16
//        icon.iconLeft = 5
//        icon.contentRight = 5
//        icon.contentColor = UIColor.theme(.textWhite)
//        icon.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
//        icon.layer.cornerRadius = 8
//        icon.clipsToBounds = true
//        return icon
//    }()
//
//    lazy var genderIcon: IconLabelView = {
//        let icon = IconLabelView(frame: .zero)
//        icon.margin = 3
//        icon.contentHeight = 16
//        icon.iconLeft = 5
//        icon.contentRight = 3
//        icon.contentColor = UIColor.theme(.textWhite)
//        icon.layer.cornerRadius = 8
//        icon.clipsToBounds = true
//        return icon
//    }()
//
//    lazy var lordTagView: UIImageView = {
//        let view = UIImageView(image: R.image.live_lord_knight_icon_30x16())
//        return view
//    }()
//
//    lazy var vipTagView: UIImageView = {
//        return UIImageView(image: R.image.vip_enabled())
//    }()
//
//    lazy var levelView: LevelView = {
//        let view = LevelView(type: .listener)
//        return view
//    }()
//
//    lazy var newbieView: UIImageView = {
//        let view = UIImageView(image: R.image.lv_listener_newbie_tag())
//        view.size = CGSize(width: 42, height: 16)
//        return view
//    }()
//
//    lazy var broadcasterLevelView: LevelView = {
//        let view = LevelView(type: .broadcaster)
//        return view
//    }()
//
//    lazy var badgeView: ImageView = {
//        let view = ImageView(frame: .zero)
//        return view
//    }()
//
//    let roleView = RoleView(frame: .zero)
//
//    var isEmpty: Bool {
//        return tagViews.isEmpty
//    }
//
//    var tagsWidth: CGFloat {
//        return tagViews.reduce(-4) { (result, tags) -> CGFloat in
//            return result + tags.0.width + 4
//        }
//    }
//
//    private var tagViews = [(Tag, UIView)]() {
//        didSet {
//            reload()
//        }
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        configureSubview()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        configureSubview()
//    }
//
//    func reload() {
//        let sortedTags = tagViews
//            .sorted { (l, r) -> Bool in
//                return l.0.rawValue < r.0.rawValue
//        }.map({ $0.1 })
//        profileStackView.addArrangedSubviews(views: sortedTags)
//    }
//
//    func update(countryCode: String?, hideLocation: Bool) {
//        guard let countryCode = countryCode,
//            !hideLocation else {
//                removeTag(.location)
//                return
//        }
//        let locale = Locale(identifier: "en")
//        let countryStr = locale.localizedString(forRegionCode: countryCode) ?? ""
//        locationIcon.iconImage = R.image.lv_location()
//        locationIcon.iconWidth = 12
//        locationIcon.contentText = countryStr
//
//        appendTag((.location, locationIcon))
//    }
//
//    func update(age: Int?, gender: Entity.Profile.Gender, hideAge: Bool) {
//        // 年龄 & 性别
//        //        guard let profile = profile else { return }
//        // 头像 & 名字
//        var genderIcon: UIImage?
//        var backgroundColor = UIColor.theme(.maleColor)
//        // 年龄
//        if hideAge {
//            self.genderIcon.contentText = nil
//        } else {
//            self.genderIcon.contentText = "\(age ?? 0)"
//        }
//        // 性别
//        self.genderIcon.iconSize = 12
//        if gender != .secret {
//            genderIcon = (gender == .male) ? R.image.lv_male_icon(): R.image.lv_female_icon()
//            backgroundColor = (gender == .male) ? UIColor.theme(.maleColor): UIColor.theme(.femaleColor)
//            self.genderIcon.iconWidth = 12
//            self.genderIcon.margin = hideAge ? 2 : 3
//            self.genderIcon.contentRight = hideAge ? 0 : 5
//            self.genderIcon.iconLeft = hideAge ? 2 : 5
//        } else {
//            genderIcon = nil
//            self.genderIcon.iconWidth = 0
//            self.genderIcon.contentRight = 5
//            self.genderIcon.iconLeft = 0 //左右间距为5
//            self.genderIcon.margin = hideAge ? 0 : 5
//            backgroundColor = UIColor.theme(.maleColor)
//        }
//
//        self.genderIcon.iconImage = genderIcon
//        self.genderIcon.backgroundColor = backgroundColor
//        if !(hideAge && gender == .secret) {
//            appendTag((.gender, self.genderIcon))
//        } else {
//            removeTag(.gender)
//        }
//    }
//
//    func update(userLevel: Int) {
//        if userLevel > 0 {
//            self.levelView.level = userLevel
//            appendTag((.userLevel, self.levelView))
//        } else {
//            removeTag(.userLevel)
//        }
//    }
//
//    func updateNewbie(userLevel: Int, hostLevel: Int) {
//
//        if App.isCuddleGroup && userLevel < 5 && hostLevel < 5 {
//            appendTag((.newbie, self.newbieView))
//            updateNewbieIcon()
//        } else {
//            removeTag(.newbie)
//        }
//    }
//
//    func update(hostLevel: Int) {
//        if hostLevel > 0 {
//            self.broadcasterLevelView.level = hostLevel
//            appendTag((.hostLevel, self.broadcasterLevelView))
//        } else {
//            removeTag(.hostLevel)
//        }
//    }
//
//    func updateNewbieIcon() {
//        self.newbieView.snp.makeConstraints { (make) in
//            make.width.equalTo(42)
//            make.height.equalTo(16)
//        }
//    }
//
//    func addAndSetTags(_ userInfo: LiveUserInfo?, role: RoleView.RoleType?) {
//        let userLevel = userInfo?.userLevel ?? 0
//        let badge = FireStore.shared.badge(for: userInfo?.badge ?? 0)
//        let hostLevel = userInfo?.hostLevel ?? 0
//
//        update(userLevel: Int(userLevel))
//        if let uid = userInfo?.suid, uid > SystemBotUid {// 小于100000 系统机器
//            updateNewbie(userLevel: Int(userLevel), hostLevel: Int(hostLevel))
//        }
//        if let rol = role {
//            update(role: rol)
//        }
//
//        updateLord(level: userInfo?.lordLevel ?? 0)
//        update(isVip: userInfo?.isVip ?? false)
//        update(badge: badge?.resource)
//
//        reload()
//    }
//
//    func update(badge: String?) {
//        if let badge = badge, !badge.isEmpty {
//            self.badgeView.gr.setImage(with: badge)
//            appendTag((.badge, self.badgeView))
//            self.badgeView.snp.makeConstraints({ (make) in
//                make.width.height.equalTo(16)
//            })
//        } else {
//            removeTag(.badge)
//        }
//    }
//
//    func updateLord(level: Int) {
//        guard level != 0 else {
//            removeTag(.lord)
//            return
//        }
//        if level == 1 {
//            lordTagView.image = R.image.live_lord_knight_icon_30x16()
//        } else if level == 2 {
//            lordTagView.image = R.image.live_lord_baron_icon_30x16()
//        } else if level == 3 {
//            lordTagView.image = R.image.live_lord_viscount_icon_30x16()
//        } else if level == 4 {
//            lordTagView.image = R.image.live_lord_count_icon_30x16()
//        } else if level == 5 {
//            lordTagView.image = R.image.live_lord_marquis_icon_30x16()
//        }
//
//        appendTag((.lord, self.lordTagView))
//        lordTagView.snp.makeConstraints { (make) in
//            make.width.equalTo(30)
//            make.height.equalTo(16)
//        }
//    }
//
//    func update(isVip: Bool) {
//        guard isVip else {
//            removeTag(.vip)
//            return
//        }
//        appendTag((.vip, self.vipTagView))
//    }
//
//    func update(role: RoleView.RoleType) {
//        guard role != .none else {
//            removeTag(.role)
//            return
//        }
//        roleView.updateRole(role: role)
//        appendTag((.role, roleView))
//    }
//
//    private func removeTag(_ tag: Tag) {
//        let item = tagViews.removeElement(ifExists: { $0.0 == tag })
//        item?.1.removeFromSuperview()
//    }
//
//    private func appendTag(_ item: (Tag, UIView)) {
//        if !tagViews.contains(where: { $0.0 == item.0 }) {
//            tagViews.append(item)
//        }
//    }
//}
