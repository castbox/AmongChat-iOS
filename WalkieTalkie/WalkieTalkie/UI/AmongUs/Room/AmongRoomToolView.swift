//
//  AmongRoomToolView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AmongRoomToolView: XibLoadableView {
    
    @IBOutlet weak var openGameButton: UIButton!
    @IBOutlet weak var nickNameButton: UIButton!
    
    private let bag = DisposeBag()
    
    var openGameHandler: CallBack?
    var setNickNameHandler: CallBack?
    var room: Entity.Room?
    var profileObserverDispose: Disposable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(_ room: Entity.Room) {
        self.room = room
        switch room.topicType {
        case .amongus, .roblox, .minecraft, .freefire:
            openGameButton.setTitle(R.string.localizable.roomTagOpenGame(), for: .normal)
        default:
            openGameButton.setTitle(room.topicName, for: .normal)
        }
        openGameButton.isUserInteractionEnabled = room.topicType != .chilling
        //, .freefire, .
        nickNameButton.isHidden = !room.topicType.enableNickName
        observerProfile()
    }
    
    private func observerProfile() {
        profileObserverDispose?.dispose()
        profileObserverDispose =
        Settings.shared.amongChatUserProfile.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] profile in
                switch self?.room?.topicType {
                case .roblox:
                    self?.nickNameButton.setTitle(profile?.nameRoblox ?? R.string.localizable.amongChatRoomSetRebloxName(), for: .normal)
                case .fortnite:
                    self?.nickNameButton.setTitle(profile?.nameFortnite ?? R.string.localizable.amongChatRoomSetFortniteName(), for: .normal)
                case .freefire:
                    self?.nickNameButton.setTitle(profile?.nameFreefire ?? R.string.localizable.amongChatRoomSetFreefireName(), for: .normal)
                case .minecraft:
                    self?.nickNameButton.setTitle(profile?.nameMineCraft ?? R.string.localizable.amongChatRoomSetMinecraftName(), for: .normal)
                default:
                    ()
                }
            })
        profileObserverDispose?.disposed(by: bag)

    }
    
    private func configureSubview() {
        nickNameButton.titleLabel?.adjustsFontSizeToFitWidth = true
        openGameButton.setBackgroundImage("592DFF".color().image, for: .normal)
        nickNameButton.setBackgroundImage(UIColor.white.image, for: .normal)
    }
    
    @IBAction func setupNickNameAction(_ sender: Any) {
        setNickNameHandler?()
    }
    
    @IBAction func openGameAction(_ sender: Any) {
        openGameHandler?()
    }
}
