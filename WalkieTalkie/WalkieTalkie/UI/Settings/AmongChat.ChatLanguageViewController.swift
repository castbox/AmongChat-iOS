//
//  AmongChat.ChatLanguageViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2021/1/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension AmongChat {
    
    class ChatLanguageViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let lb = n.titleLabel
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.settingChatLanguage()
            let btn = n.leftBtn
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            return n
        }()
        
        private lazy var languagesTable: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.showsVerticalScrollIndicator = false
            tb.register(LanguageCell.self, forCellReuseIdentifier: NSStringFromClass(LanguageCell.self))
            tb.backgroundColor = UIColor.theme(.backgroundBlack)
            tb.dataSource = self
            tb.delegate = self
            tb.separatorStyle = .none
            tb.rowHeight = 73
            return tb
        }()
        
        private lazy var dataSource: [LanguageViewModel] = {
            return languages.map(languageViewModelMapping(lan:))
        }()
        {
            didSet {
                languagesTable.reloadData()
            }
        }
        
        override var screenName: Logger.Screen.Node.Start {
            .chat_language
        }
        
        private let languages: [Entity.GlobalSetting.KeyValue]
        
        init(with languages: [Entity.GlobalSetting.KeyValue]) {
            self.languages = languages
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
            Logger.Action.log(.settings_chat_language_imp)
        }
        // MARK: - UI action
        
        @objc
        private func onBackBtn() {
            navigationController?.popViewController()
        }
        
        private func setupLayout() {
            
            view.addSubviews(views: navView, languagesTable)
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            languagesTable.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
                maker.top.equalTo(navView.snp.bottom)
            }
        }
        
        private func setupEvent() {
            
            Settings.shared.preferredChatLanguage.replay()
                .filterNil()
                .skip(1)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    self.dataSource = self.languages.map(self.languageViewModelMapping(lan:))
                })
                .disposed(by: bag)
        }
        
        private func updateChatLanguage(_ lan: LanguageViewModel) {
            
            guard !lan.isSelected else {
                return
            }
            
            let profileProto = Entity.ProfileProto(chatLanguage: lan.languageKey)
            
            let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
            let removal = { [weak self] in
                hudRemoval()
                self?.languagesTable.isUserInteractionEnabled = true
            }
            languagesTable.isUserInteractionEnabled = false
            Request.updateProfile(profileProto)
                .do(onDispose: {
                    removal()
                })
                .subscribe(onSuccess: { [weak self] (profile) in
                    guard let p = profile else {
                        return
                    }
                    Settings.shared.amongChatUserProfile.value = p
                    ChatLanguageHelper.updateCurrentLanguage(lan.language)
                    self?.navigationController?.popViewController()
                }, onError: { [weak self] (error) in
                    self?.view.raft.autoShow(.text(error.localizedDescription))
                })
                .disposed(by: bag)
        }
        
        private func languageViewModelMapping(lan: Entity.GlobalSetting.KeyValue) -> LanguageViewModel {
            var vm = LanguageViewModel(language: lan)
            vm.isSelected = ChatLanguageHelper.currentLanguage(from: languages).key == lan.key
            return vm
        }

    }
    
}

extension AmongChat.ChatLanguageViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LanguageCell.self), for: indexPath) as! LanguageCell
        if let lan = dataSource.safe(indexPath.row) {
            cell.bindViewModel(lan)
        }
        return cell
    }
    
}

extension AmongChat.ChatLanguageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let lan = dataSource.safe(indexPath.row) else {
            return
        }
        updateChatLanguage(lan)
        Logger.Action.log(.settings_chat_language_clk, lan.languageKey)

    }
}

extension AmongChat.ChatLanguageViewController {
    
    struct LanguageViewModel {
        let language: Entity.GlobalSetting.KeyValue
        var isSelected: Bool = false
        
        var languageName: String {
            return language.value
        }
        
        var languageKey: String {
            return language.key
        }
        
    }
    
}

extension AmongChat.ChatLanguageViewController {
    
    class LanguageCell: TableViewCell {
                
        private lazy var leftLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = UIColor(hex6: 0xFFFFFF)
            return lb
        }()
        
        private lazy var rightIcon: UIImageView = {
            let iv = UIImageView(image: R.image.ac_setting_check())
            return iv
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        private func setupLayout() {
            selectionStyle = .none
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: leftLabel, rightIcon)
                        
            leftLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(20)
                maker.right.lessThanOrEqualTo(rightIcon.snp.left).offset(-24)
            }
            
            rightIcon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(20)
                maker.right.equalToSuperview().inset(20)
            }
        }
        
        func bindViewModel(_ viewModel: LanguageViewModel) {
            
            leftLabel.text = viewModel.languageName
            if viewModel.isSelected {
                rightIcon.isHidden = false
            } else {
                rightIcon.isHidden = true
            }
        }
    }
    
}
