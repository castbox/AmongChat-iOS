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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(_ room: Entity.Room) {
        switch room.topicId {
        case .amongus:
            openGameButton.setTitle(R.string.localizable.roomTagOpenGame(), for: .normal)
        case .roblox:
//            if room. {
//                <#code#>
//            }
            openGameButton.setTitle(R.string.localizable.roomTagOpenGame(), for: .normal)
            
        default:
            openGameButton.setTitle(R.string.localizable.roomTagChilling(), for: .normal)
        }
        openGameButton.isUserInteractionEnabled = room.topicId != .chilling
        nickNameButton.isHidden = room.topicId != .roblox
    }
    
    private func bindSubviewEvent() {
        Settings.shared.amongChatUserProfile.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] profile in
                if let nickName = profile?.nickname {
                    self?.nickNameButton.setTitle(nickName, for: .normal)
                } else {
                    self?.nickNameButton.setTitle(R.string.localizable.amongChatRoomSetRebloxName(), for: .normal)
                }
            })
            .disposed(by: bag)

    }
    
    private func configureSubview() {
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
