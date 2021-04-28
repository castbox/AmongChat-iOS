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
import MarqueeLabel

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
    @IBOutlet weak var notesView: UIView!
    
    @IBOutlet weak var robloxContainer: UIView!
    @IBOutlet weak var robloxLinkButton: UIButton!
    @IBOutlet weak var robloxLinkEditButton: UIButton!
    
    private lazy var marqueueLabel: MarqueeLabel = {
        let label = MarqueeLabel()
        label.font = R.font.nunitoExtraBold(size: 14)!
        label.textColor = .white
        label.backgroundColor = .clear
        label.type = .continuous
        label.fadeLength = 20
        return label
    }()
    
    private weak var tipView: EasyTipView?
    private weak var tipBgView: UIView?
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
                    notesView.isHidden = true
                case .roblox:
                    robloxContainer.isHidden = !group.robloxLink.isValid
                    setupButton.isHidden = group.robloxLink.isValid
                    
                    setupButton.setTitle(R.string.localizable.groupRoomSetUpLink(), for: .normal)
                    
                    let titleString = NSAttributedString(string: group.robloxLink ?? "", attributes: [NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue])
                    robloxLinkButton.setAttributedTitle(titleString, for: .normal)
                    robloxLinkEditButton.setImage(R.image.ac_group_room_rb_edit(), for: .normal)
                    
                    amongUsContainer.isHidden = true
                    notesView.isHidden = true
                default:
//                    marqueueLabel.textList = ["\(R.string.localizable.roomHostsNotes()) \(group.note ?? "")"]
                    notes = "\(R.string.localizable.roomHostsNotes()) \(group.note ?? "")"
                    setupButton.isHidden = group.note.isValid
                    notesView.isHidden = !group.note.isValid
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
                    notesView.isHidden = true
                case .roblox:
                    robloxContainer.isHidden = !group.robloxLink.isValid
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.lineBreakMode = .byTruncatingTail
                    let titleString = NSAttributedString(string: group.robloxLink ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue, NSAttributedString.Key.paragraphStyle: paragraph])
                    robloxLinkButton.setAttributedTitle(titleString, for: .normal)
                    robloxLinkEditButton.setImage(R.image.ac_group_room_copy(), for: .normal)
                    amongUsContainer.isHidden = true
                    notesView.isHidden = true
                default:
                    //                    setupButton.isHidden = group.note.isValid
                    notes = "\(R.string.localizable.roomHostsNotes()) \(group.note ?? "")"
                    notesView.isHidden = !group.note.isValid
                    //                    setupButton.setTitle(R.string.localizable.groupRoomSetUpNotes(), for: .normal)
                    robloxContainer.isHidden = true
                    amongUsContainer.isHidden = true
                    //show notes
                    if !haveShowNoteTips, group.note.isValid {
                        haveShowNoteTips = true
                        //delay
                        mainQueueDispatchAsync(after: 0.2) { [weak self] in
                            self?.notesClickAction()
                        }
                    }
                }
                setupButton.isHidden = true
            }
            
            if !notesView.isHidden {
//                marqueueLabel.showFirstText()
//                marqueueLabel.fa = 50
//                marqueueLabel.run
            } else {
//                marqueueLabel.stop()
            }
        }
    }
    
    var notes: String? {
        set {
            guard let wrappedNotes = newValue, wrappedNotes != notes else {
                return
            }
            marqueueLabel.text = wrappedNotes
        }
        get { marqueueLabel.text }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubview()
        bindSubviewEvent()
    }
    
    private func bindSubviewEvent() {
        marqueueLabel.rx.tapGesture()
            .subscribe(onNext: { [weak self] _ in
                self?.notesClickAction()
            })
            .disposed(by: bag)
    }
    
    private func configureSubview() {
        notesView.addSubview(marqueueLabel)
        marqueueLabel.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.left.equalTo(8)
        }
    }
    
    func dismissTipsView() {
        scheduleDispose?.dispose()
        tipView?.dismiss()
        tipView = nil
        tipBgView?.removeFromSuperview()
        tipBgView = nil
    }
    
    @IBAction func robloxLinkTapAction(_ sender: Any) {
        guard let urlString = group?.robloxLink, let url = URL(string: urlString) else {
            group?.robloxLink?.copyToPasteboardWithHaptic()
            return
        }
        containingController?.open(url: url)
    }
    @IBAction func robloxCopyAction(_ sender: Any) {
        //
        if group?.loginUserIsAdmin == true {
            //edit
            actionHandler?(.setupLink)
        } else {
            Logger.Action.log(.group_roblox_link_copy)
            //copy
            group?.robloxLink?.copyToPasteboardWithHaptic()
        }
        
    }
    
    func notesClickAction() {
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
        preferences.positioning.bubbleInsets = UIEdgeInsets(top: 8, left: 20, bottom: 0, right: 20)
        preferences.drawing.cornerRadius = 12
        preferences.animating.dismissDuration = 0.5
        preferences.animating.showDuration = 0.5
        
        let bgView = UIView(frame: Frame.Screen.bounds)
        bgView.rx.tapGesture()
            .subscribe(onNext: { [weak self] gesture in
                gesture.view?.removeFromSuperview()
                self?.dismissTipsView()
            })
            .disposed(by: bag)
        self.tipBgView = bgView
        containingController?.view.addSubview(bgView)
        
        let view = AmongGroupRoomTipsView()
        view.editHandler = { [weak self] in
            self?.actionHandler?(.setupNotes)
        }
        let viewSize = view.update(group)
        view.size = viewSize
        let tipView = EasyTipView(contentView: view,
                              preferences: preferences,
                              delegate: self)
        tipView.tag = 0
        tipView.show(animated: true, forView: marqueueLabel, withinSuperview: containingController?.view)
        self.tipView = tipView
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
            Logger.Action.log(.group_amongus_code_copy)
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
