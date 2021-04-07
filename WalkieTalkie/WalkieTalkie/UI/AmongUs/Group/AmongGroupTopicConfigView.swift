//
//  AmongGroupTopicConfigView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import EasyTipView
import RxSwift
import RxCocoa

class AmongGroupTopicConfigView: XibLoadableView {
    
    enum Action {
        case setupCode
        case setupLink
        case setupNotes
    }
    
    @IBOutlet weak var setupButton: UIButton!
    
    @IBOutlet weak var amongUsContainer: UIView!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var serviceLocationButton: UIButton!
    @IBOutlet weak var actionIcon: UIImageView!
    //justchatting 房间如果设置了 notes, 听众会有此按钮
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var robloxContainer: UIView!
    @IBOutlet weak var robloxLinkButton: UIButton!
    @IBOutlet weak var robloxLinkEditButton: UIButton!
    private var tipView: EasyTipView?
    private let bag = DisposeBag()
    
    var actionHandler: ((Action) -> Void)?
    
    var group: Entity.GroupRoom? {
        didSet {
            guard let group = group else {
                return
            }
            //admin or user
            if group.loginUserIsAdmin {
                switch group.topicType {
                case .amongus:
                    codeLabel.text = group.amongUsCode?.uppercased()
                    serviceLocationButton.setTitle(group.amongUsZone?.title, for: .normal)
                    amongUsContainer.isHidden = !group.amongUsCode.isValid
                    setupButton.isHidden = group.amongUsCode.isValid
                    if group.userList.first?.uid == Settings.loginUserId {
                        actionIcon.image = R.image.ac_room_code_edit()
                    } else {
                        actionIcon.image = R.image.ac_room_code_copy()
                    }
                    setupButton.setTitle(R.string.localizable.groupRoomSetUpCode(), for: .normal)
                    
                    //
                    robloxContainer.isHidden = true
                    notesButton.isHidden = true
                case .roblox:
                    robloxContainer.isHidden = !group.robloxLink.isValid
                    setupButton.isHidden = group.robloxLink.isValid
                    
                    setupButton.setTitle(R.string.localizable.groupRoomSetUpLink(), for: .normal)
                    
                    let titleString = NSAttributedString(string: group.robloxLink ?? "", attributes: [NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue])
                    robloxLinkButton.setAttributedTitle(titleString, for: .normal)
                    robloxLinkEditButton.setImage(R.image.ac_group_room_rb_edit(), for: .normal)
                    
                    amongUsContainer.isHidden = true
                    notesButton.isHidden = true
                default:
                    setupButton.isHidden = group.note.isValid
                    notesButton.isHidden = !group.note.isValid
                    setupButton.setTitle(R.string.localizable.groupRoomSetUpNotes(), for: .normal)
                    robloxContainer.isHidden = true
                    amongUsContainer.isHidden = true
                }
            } else {
                switch group.topicType {
                case .amongus:
                    
                    codeLabel.text = group.amongUsCode?.uppercased()
                    serviceLocationButton.setTitle(group.amongUsZone?.title, for: .normal)
                    amongUsContainer.isHidden = !group.amongUsCode.isValid
                    //                    setupButton.isHidden = group.amongUsCode.isValid
                    if group.userList.first?.uid == Settings.loginUserId {
                        actionIcon.image = R.image.ac_room_code_edit()
                    } else {
                        actionIcon.image = R.image.ac_room_code_copy()
                    }
                    //                    setupButton.setTitle(R.string.localizable.groupRoomSetUpCode(), for: .normal)
                    
                    //
                    robloxContainer.isHidden = true
                    notesButton.isHidden = true
                case .roblox:
                    robloxContainer.isHidden = !group.robloxLink.isValid
                    //                    setupButton.isHidden = group.robloxLink.isValid
                    
                    //                    setupButton.setTitle(R.string.localizable.groupRoomSetUpLink(), for: .normal)
                    
                    let titleString = NSAttributedString(string: group.robloxLink ?? "", attributes: [NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue])
                    robloxLinkButton.setAttributedTitle(titleString, for: .normal)
                    robloxLinkEditButton.setImage(R.image.ac_group_room_copy(), for: .normal)
                    amongUsContainer.isHidden = true
                    notesButton.isHidden = true
                default:
                    //                    setupButton.isHidden = group.note.isValid
                    notesButton.isHidden = !group.note.isValid
                    //                    setupButton.setTitle(R.string.localizable.groupRoomSetUpNotes(), for: .normal)
                    robloxContainer.isHidden = true
                    amongUsContainer.isHidden = true
                }
                setupButton.isHidden = true
            }
        }
    }
    
    @IBAction func robloxCopyAction(_ sender: Any) {
        //
        if group?.loginUserIsAdmin == true {
            //edit
            actionHandler?(.setupLink)
        } else {
//            actionHandler?(.setupLink)
            
            //copy
            group?.robloxLink?.copyToPasteboardWithHaptic()
        }
        
    }
    
    @IBAction func notesButtonAction(_ sender: Any) {
        guard let group = group else {
            return
        }
        //show notes
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = R.font.nunitoExtraBold(size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        preferences.drawing.foregroundColor = .black
        preferences.drawing.backgroundColor = .white
        preferences.drawing.arrowPosition = .top
        preferences.positioning.contentInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        preferences.drawing.cornerRadius = 12
        
        let view = AmongGroupRoomTipsView()
        let viewSize = view.update(group)
        view.size = viewSize
        tipView = EasyTipView(contentView: view,
                              preferences: preferences,
                              delegate: self)
        tipView?.tag = 0
        tipView?.show(animated: true, forView: notesButton, withinSuperview: containingController?.view)
        Observable<Int>
            .interval(.seconds(5), scheduler: MainScheduler.instance)
            .single()
            .subscribe(onNext: { [weak welf = self] _ in
                guard let `self` = welf else { return }
                self.tipView?.dismiss()
            })
            .disposed(by: self.bag)
        //

    }
    @IBAction func setupButtonAction(_ sender: Any) {
        if group?.loginUserIsAdmin == true {
            switch group?.topicType {
            case .amongus:
                actionHandler?(.setupCode)
            case .roblox:
                actionHandler?(.setupLink)
            default:
                actionHandler?(.setupLink)
            }
        }
        notesButtonAction(sender)
    }
}

extension AmongGroupTopicConfigView: EasyTipViewDelegate {
    func easyTipViewDidTap(_ tipView: EasyTipView) {
//        dismissTipView()
        self.tipView?.dismiss()
    }
    
    func easyTipViewDidDismiss(_ tipView : EasyTipView) {
        
    }
}
