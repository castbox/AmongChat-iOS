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
    private var scheduleDispose: Disposable?
    
    var actionHandler: ((Action) -> Void)?
    var haveShowNoteTips = false
    
    var group: Entity.Group? {
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
                    if group.loginUserIsAdmin {
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
                    actionIcon.image = R.image.ac_room_code_copy()
                    robloxContainer.isHidden = true
                    notesButton.isHidden = true
                case .roblox:
                    robloxContainer.isHidden = !group.robloxLink.isValid
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.lineBreakMode = .byTruncatingTail
                    let titleString = NSAttributedString(string: group.robloxLink ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue, NSAttributedString.Key.paragraphStyle: paragraph])
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
                    //show notes
                    if !haveShowNoteTips, group.note.isValid {
                        haveShowNoteTips = true
                        //delay
                        mainQueueDispatchAsync(after: 0.2) { [weak self] in
                            self?.notesButtonAction(self?.notesButton)
                        }
                    }
                }
                setupButton.isHidden = true
            }
        }
    }
    func dismissTipsView() {
        scheduleDispose?.dispose()
        tipView?.dismiss()
        tipView = nil
    }
    
    @IBAction func robloxCopyAction(_ sender: Any) {
        //
        if group?.loginUserIsAdmin == true {
            //edit
            actionHandler?(.setupLink)
        } else {
            //copy
            group?.robloxLink?.copyToPasteboardWithHaptic()
            containingController?.view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false, backColor: UIColor(hex6: 0x181818))
        }
        
    }
    
    @IBAction func notesButtonAction(_ sender: Any) {
        guard let group = group, tipView == nil  else {
            dismissTipsView()
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
        preferences.animating.dismissDuration = 0.5
        preferences.animating.showDuration = 0.5
        
        let view = AmongGroupRoomTipsView()
        view.editHandler = { [weak self] in
            self?.actionHandler?(.setupNotes)
        }
        let viewSize = view.update(group)
        view.size = viewSize
        tipView = EasyTipView(contentView: view,
                              preferences: preferences,
                              delegate: self)
        tipView?.tag = 0
        tipView?.show(animated: true, forView: notesButton, withinSuperview: containingController?.view)
        scheduleDispose = Observable<Int>
            .interval(.seconds(5), scheduler: MainScheduler.instance)
            .single()
            .subscribe(onNext: { [weak self] _ in
                self?.dismissTipsView()
            })
        scheduleDispose?.disposed(by: bag)
    }
    
    @IBAction func setupButtonAction(_ sender: Any) {
        if group?.loginUserIsAdmin == true {
            switch group?.topicType {
            case .amongus:
                actionHandler?(.setupCode)
            case .roblox:
                actionHandler?(.setupLink)
            default:
                actionHandler?(.setupNotes)
            }
        }
    }
    @IBAction func amongUsContainerAction(_ sender: Any) {
        if group?.loginUserIsAdmin == true {
            actionHandler?(.setupCode)
        } else {
            group?.amongUsCode?.copyToPasteboardWithHaptic()
        }
        
    }
}

extension AmongGroupTopicConfigView: EasyTipViewDelegate {
    func easyTipViewDidTap(_ tipView: EasyTipView) {
        dismissTipsView()
    }
    
    func easyTipViewDidDismiss(_ tipView : EasyTipView) {
        dismissTipsView()
    }
}
