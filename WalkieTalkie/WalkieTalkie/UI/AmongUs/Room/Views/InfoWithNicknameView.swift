//
//  InfoWithNicknameView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/4.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class InfoWithNicknameView: XibLoadableView {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    private let bag = DisposeBag()
    
    var room: Entity.Room? = nil {
        didSet {
            updateInfo()
        }
    }

    var setNickNameHandler: CallBack?

    override init(frame: CGRect) {
        super.init(frame: frame)
        observerProfile()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        observerProfile()
    }
    
    private func observerProfile() {
        Settings.shared.amongChatUserProfile.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] profile in
                self?.updateInfo()
            })
            .disposed(by: bag)
    }
    
    private func updateInfo() {
        guard let profile = Settings.shared.amongChatUserProfile.value else {
            return
        }
        var nameTxt: String? = nil
        var inGameNameName: String = ""
        var nameTxtAlignment = NSTextAlignment.center
        
        switch room?.topicType {
        case .roblox:
            if let name = profile.nameRoblox,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomRobloxUserNamePrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetRebloxName()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomRobloxUserName()
            
        case .fortnite:
            
            if let name = profile.nameFortnite,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomFortniteNamePrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetFortniteName()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomFortniteName()
            
        case .freefire:
            
            if let name = profile.nameFreefire,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomFreefireNamePrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetFreefireName()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomFreefireName()
            
        case .minecraft:
            
            if let name = profile.nameMineCraft,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomMinecraftNamePrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetMinecraftName()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomMinecraftName()
            
        case .mobilelegends:
            
            if let name = profile.nameMobilelegends,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomMobileLegendsNamePrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetMobileLegendsName()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomMobileLegendsName()
            
        case .pubgmobile:
            
            if let name = profile.namePubgmobile,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomPubgNameIdPrefix(name)
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetPubgMobileName()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomPubgNameId()
            
        case .callofduty:
            
            if let name = profile.nameCallofduty,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomCallOfDutyNamePrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetCallOfDutyName()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomCallOfDutyName()
            
        case .animalCrossing:
            
            if let name = profile.nameAnimalCrossing,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomAnimalCrossingIdPrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetAnimalCrossingId()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomAnimalCrossingId()
            
        case .brawlStars:
            if let name = profile.nameBrawlStars,
               !name.isEmpty {
                nameTxt = R.string.localizable.amongChatRoomBrawlIdPrefix(name)
                nameTxtAlignment = .left
            } else {
                nameTxt = R.string.localizable.amongChatRoomSetBrawlId()
                nameTxtAlignment = .center
            }
            
            inGameNameName = R.string.localizable.amongChatRoomBrawlId()
            
        default:
            //                    #if DEBUG
            //                    assertionFailure()
            //                    #endif
            ()
        }
        nameLabel.text = nameTxt
        nameLabel.textAlignment = nameTxtAlignment
        descLabel.text = R.string.localizable.amongChatRoomSetUpNameDesc(inGameNameName)
    }
    
    @IBAction func setupNickNameAction(_ sender: Any) {
        setNickNameHandler?()
    }
    
}
