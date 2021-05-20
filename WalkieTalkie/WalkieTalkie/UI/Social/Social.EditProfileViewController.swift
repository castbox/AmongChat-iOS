//
//  Social.EditProfileViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SnapKit
import IQKeyboardManagerSwift

extension Social {
    class EditProfileViewController: ViewController {
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_back(), for: .normal)
            n.titleLabel.text = R.string.localizable.profileEditTitle()
            return n
        }()
        
        private lazy var saveBtn: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setBackgroundImage("#FFF000".color().image, for: .normal)
            btn.setTitle(R.string.localizable.profileEditSaveBtn(), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(.black, for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 17, bottom: 0, right: 17)
            btn.cornerRadius = 16
            return btn
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.showsVerticalScrollIndicator = false
            tb.register(Cell.self, forCellReuseIdentifier: NSStringFromClass(Cell.self))
            tb.backgroundColor = UIColor.theme(.backgroundBlack)
            tb.dataSource = self
            tb.delegate = self
            tb.separatorStyle = .none
            tb.rowHeight = 73
            return tb
        }()
        
        private lazy var options: [Option] = generateDataSource() {
            didSet {
                tableView.reloadData()
            }
        }
                
        private lazy var userInputView = AmongInputNickNameView()
        
        private lazy var headerView = TableHeaderView()
        private lazy var footerView = TableFotterView()
        
        private var profile: Entity.UserProfile! = Settings.shared.amongChatUserProfile.value!
        
        //new update
        private var profileProto = Entity.ProfileProto() {
            didSet {
                reloadData()
            }
        }
        
        override var screenName: Logger.Screen.Node.Start {
            return .profile_edit
        }
        
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            IQKeyboardManager.shared.enable = true
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            IQKeyboardManager.shared.enable = false
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            if touches.first?.view == userInputView.xibView {
                view.endEditing(true)
            }
        }
    }
}

extension Social.EditProfileViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(Cell.self), for: indexPath) as! Cell
        
        if let option = options.safe(indexPath.row) {
            cell.configCell(with: option)
        }
        
        //for location
        cell.switchValueChanged = { [weak self] value in
            self?.profileProto.hideLocation = value
        }
        
        return cell
    }
}

extension Social.EditProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = options.safe(indexPath.row),
              option.type != .location else {
            return
        }
        
        option.selectionHandler()
    }
    
}


extension Social.EditProfileViewController {
    struct Option {
        
        enum OptionType {
            case nickname
            case birthday
            case pronoun
            case location
        }
        
        let type: OptionType
        var rightText: String? = nil
        let selectionHandler: (() -> Void)
                
        var leftText: String {
            switch type {
            case .nickname:
                return R.string.localizable.profileNickname()
            case .birthday:
                return R.string.localizable.profileBirthday()
            case .pronoun:
                return R.string.localizable.profilePronoun()
            case .location:
                return R.string.localizable.profileHideLocation()
            }
        }
        
        var rightIcon: UIImage? {
            switch type {
            default:
                return R.image.ac_right_arrow()
            }
        }
        
    }
    
    private func generateDataSource() -> [Option] {
        guard let profile = profile else {
            return []
        }
        var birthday: String? {
            guard let b = profileProto.birthday ?? profile.birthday, !b.isEmpty else {
                return nil
            }
            return self.fixBirthdayString(b)
        }
        
        var pronounString: String? {
            guard profileProto.gender != nil else {
                return profile.pronoun.title
            }
            return profileProto.pronoun.title
        }
        
        let options: [Option] = [
            Option(type: .nickname, rightText: profileProto.name ?? profile.name, selectionHandler: { [weak self] in
                Logger.Action.log(.profile_nikename_clk, category: nil)
                _ = self?.userInputView.becomeFirstResponder(with: self?.profileProto.name ?? self?.profile.name)
            }),
            Option(type: .birthday, rightText: birthday, selectionHandler: { [weak self] in
                Logger.Action.log(.profile_birthday_clk, category: nil)
                self?.selectBirthday()
            }),
            Option(type: .pronoun, rightText: pronounString, selectionHandler: { [weak self] in
                self?.showPronounSheet()
            }),
            Option(type: .location, rightText: (profileProto.hideLocation ?? profile.hideLocation)?.int.string,  selectionHandler: { 
//                self?.shareApp()
            }),
        ]
        
        return options
    }
    
    func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor.theme(.backgroundBlack)
        view.addSubviews(views: navView, tableView)
        
        navView.addSubview(saveBtn)
        saveBtn.snp.makeConstraints { maker in
            maker.trailing.equalTo(-20)
            maker.height.equalTo(32)
            maker.centerY.equalToSuperview()
        }
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        tableView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(navView.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
        tableView.reloadData()
        
        view.addSubview(userInputView)
        userInputView.alpha = 0
        userInputView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    
    func setupData() {
        
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        
        Settings.shared.amongChatUserProfile.replay()
            .filterNil()
            .subscribe(onNext: { [weak self] (profile) in
                removeBlock()
                self?.updateFields(profile: profile)
            }, onError: { (_) in
                removeBlock()
            })
            .disposed(by: bag)
        
        userInputView.inputResultHandler = { [weak self](text) in
            guard let `self` = self else { return }
            self.profileProto.name = text
            IQKeyboardManager.shared.enable = true
        }
        
        headerView.avatarIV.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.onAvatarTapped()
            })
            .disposed(by: bag)
        
        Observable.merge([
            userInputView.textField.rx.controlEvent(.editingDidBegin).map { false },
            userInputView.textField.rx.controlEvent(.editingDidEnd).map { true }
        ])
        .subscribe(onNext: { enable in
            IQKeyboardManager.shared.enable = enable
        })
        .disposed(by: bag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] (height) in
                guard let `self` = self, self.userInputView.isFirstResponder else { return }
                self.userInputView.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-height)
                }
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
            }).disposed(by: bag)
        
        Settings.shared.amongChatAvatarListShown.replay()
            .subscribe(onNext: { [weak self] (ts) in
                if let _ = ts {
                    self?.headerView.randomIconIV.badgeOff()
                } else {
                    self?.headerView.randomIconIV.badgeOn(hAlignment: .tailByTail(-2), diameter: 8, borderWidth: 0, borderColor: nil)
                }
            })
            .disposed(by: bag)
        
        saveBtn.rx.tap
            .subscribe(onNext:  { [weak self] in
                self?.updateProfileIfNeeded()
            })
            .disposed(by: bag)
        
        footerView.descriptionView.isEdtingRelay
            .subscribe(onNext: { [weak self] isEditing in
                guard let `self` = self, !isEditing else { return }
                self.profileProto.description = self.footerView.descriptionView.inputTextView.text
            })
            .disposed(by: bag)
    }
    
    func showPronounSheet() {
        AmongSheetController.show(with: nil,
                                  items: [.pronounShe, .pronounHe, .pronounThey, .pronounOther, .pronounNotShare, .cancel],
                                  in: self,
                                  uiType: .none) { [weak self] item in
            guard item != .cancel,
                  let genderValue = item.rawValue.int else {
                return
            }
            self?.profileProto.gender = genderValue
        }
    }
    
    func selectBirthday() {
        let vc = Social.BirthdaySelectViewController()
        vc.onCompletion = { [weak self] (birthdayStr, constellation) in
            guard let `self` = self else {
                return
            }
            self.profileProto.birthday = birthdayStr
            self.profileProto.constellation = constellation
        }
        vc.showModal(in: self)
        
        if let b = profile.birthday, !b.isEmpty {
            vc.selectToBirthday(fixBirthdayString(b))
        } else {
            vc.selectToBirthday("2005/01/01")
        }
        view.endEditing(true)
    }
    
    func reloadData() {
        footerView.userDescription = profileProto.description ?? profile.description
        options = generateDataSource()
    }
    
    func fixBirthdayString(_ text: String) -> String {
        var b = text
        b.addString("/", at: 4)
        b.addString("/", at: 7)
        return b
    }
    
    func updateFields(profile: Entity.UserProfile) {
        self.profile = profile
        headerView.avatarIV.updateAvatar(with: profile)
        reloadData()
    }
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
    
    @objc
    func onAvatarTapped() {        
        let vc = Social.CustomAvatarViewController()
        vc.modalPresentationStyle = .overCurrentContext
        present(vc, animated: false)
    }
    
    func updateProfileIfNeeded() {
        view.endEditing(true)
        //
        guard !footerView.descriptionView.inputTextView.isFirstResponder else {
            return
        }
        let profileProto = self.profileProto
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        Request.updateProfile(profileProto)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (profile) in
                if let p = profile {
                    Settings.shared.amongChatUserProfile.value = p
                    if let birthdayStr = profileProto.birthday {
                        Logger.Action.log(.profile_birthday_update_success, category: nil, birthdayStr)
                    }
                }
                self?.navigationController?.popViewController()
            }, onError: { (error) in
                hudRemoval()
            })
            .disposed(by: bag)
    }
}

extension Social.EditProfileViewController {
    
    class TableHeaderView: UIView {
        lazy var avatarIV: AvatarImageView = {
            let iv = AvatarImageView()
            iv.isUserInteractionEnabled = true
            return iv
        }()
        
        lazy var randomIconIV: UIImageView = {
            let iv = UIImageView()
            iv.image = R.image.profile_avatar_random_btn()
            return iv
        }()
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 167))
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func configureSubview() {
            addSubviews(views: avatarIV, randomIconIV)
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(40)
                maker.width.height.equalTo(100)
                maker.centerX.equalToSuperview()
            }

            randomIconIV.snp.makeConstraints { (maker) in
                maker.bottom.equalTo(avatarIV)
                maker.trailing.equalTo(avatarIV.snp.trailing).offset(-4)
                maker.width.height.equalTo(24)
            }
        }
    }
    
    class TableFotterView: UIView {
        private lazy var descriptionTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 20)
            l.textColor = .white
            l.adjustsFontSizeToFitWidth = true
            l.text = R.string.localizable.profileBio()
            return l
        }()
        
        private(set) lazy var descriptionView: FansGroup.Views.GroupDescriptionView = {
            let d = FansGroup.Views.GroupDescriptionView()
            d.placeholderLabel.text = R.string.localizable.profileSetBio()
            d.inputTextView.keyboardDistanceFromTextField = 49
            return d
        }()
        
        var userDescription: String? {
            set { descriptionView.inputTextView.text = newValue }
            get { descriptionView.inputTextView.text }
        }
        
        override init(frame: CGRect) {
            super.init(frame: CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 200))
            configureSubview()
            bindSubviewEvent()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            
        }
        
        private func configureSubview() {
            addSubviews(views: descriptionTitleLabel, descriptionView)
            
            descriptionTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(22)
                maker.top.equalTo(23)
            }
            
            descriptionView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.top.equalTo(descriptionTitleLabel.snp.bottom).offset(16)
                maker.height.equalTo(124.5)
            }
        }
    }
    
    class Cell: TableViewCell {
        
        private lazy var leftLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor(hex6: 0xFFFFFF)
            return lb
        }()
                
        private lazy var rightLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor(hex6: 0xFFFFFF)
            return lb
        }()
        
        private lazy var rightIcon: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var switchControl: UISwitch = {
            let sw = UISwitch()
            sw.isOn = false
            sw.onTintColor = "#FFF000".color()
            sw.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.3)
            sw.layer.cornerRadius = sw.bounds.height / 2
            sw.layer.borderWidth = 0
            sw.layer.borderColor = UIColor.clear.cgColor
            return sw
        }()
        
        let bag = DisposeBag()
        
        var switchValueChanged: ((Bool) -> Void)?

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
            bindSubviewEvent()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func bindSubviewEvent() {
            switchControl.rx.isOn
                .subscribe { [weak self] value in
                    self?.switchValueChanged?(value)
                }
                .disposed(by: bag)

        }
                
        private func setupLayout() {
        
            selectionStyle = .none
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: leftLabel, rightLabel, rightIcon, switchControl)
            
            leftLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.trailing.lessThanOrEqualTo(rightLabel.snp.leading).offset(-8)
            }
            
            rightLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.greaterThanOrEqualTo(leftLabel.snp.trailing).offset(16)
                maker.trailing.equalTo(rightIcon.snp.leading).offset(-8)
            }
            
            rightIcon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(20)
                maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
            }
            
            switchControl.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
            }
        }
        
        func configCell(with option: Option) {
            
//            leftIcon.image = option.leftIcon
            leftLabel.text = option.leftText
            rightLabel.text = option.rightText
            rightIcon.image = option.rightIcon
            
            if option.type == .location {
                switchControl.isOn = option.rightText?.bool ?? false
                switchControl.isHidden = false
                rightLabel.isHidden = true
                rightIcon.isHidden = true
            } else {
                switchControl.isHidden = true
                rightLabel.isHidden = false
                rightIcon.isHidden = false
            }
        }
        
    }
    
}
