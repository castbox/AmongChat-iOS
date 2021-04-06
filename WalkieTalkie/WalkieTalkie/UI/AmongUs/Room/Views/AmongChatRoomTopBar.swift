//
//  AmongChatRoomTopBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongChatRoomTopBar: XibLoadableView {

    @IBOutlet weak var publicButton: UIButton!
    @IBOutlet weak var kickButton: BottomTitleButton!
    @IBOutlet weak var leaveButton: BottomTitleButton!
    @IBOutlet weak var nextButton: BottomTitleButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var stackView: UIStackView!
    var room: Entity.Room?
    var changePublicStateHandler: CallBack?
    var leaveHandler: CallBack?
    var kickOffHandler: CallBack?
    var reportHandler: CallBack?
    var nextRoomHandler: CallBack?
    
    var isIndicatorAnimate: Bool = false {
        didSet {
            if isIndicatorAnimate {
                indicatorView.startAnimating()
            } else {
                indicatorView.stopAnimating()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        publicButton.titleLabel?.adjustsFontSizeToFitWidth = true
        leaveButton.titleLabel?.adjustsFontSizeToFitWidth = true
        nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
        //remote config
        if !Settings.shared.showQuickChangeRoomButton {
            nextButton.isHidden = true
            stackView.removeArrangedSubview(nextButton)
        } else {
            nextButton.isHidden = false
        }
//        leaveButton.titleLabel?.numberOfLines = 0
    }
    
    func set(_ room: Entity.Room) {
        switch room.state {
        case .public:
            publicButton.setTitle(R.string.localizable.roomPublic(), for: .normal)
            publicButton.setBackgroundImage("592DFF".color().image, for: .normal)
        case .private:
            publicButton.setTitle(R.string.localizable.roomPrivate(), for: .normal)
            publicButton.setBackgroundImage("E6309E".color().image, for: .normal)
        }
        kickButton.isHidden = !room.loginUserIsAdmin
        self.room = room
//        publicButton.isUserInteractionEnabled = room.loginUserIsAdmin
    }
    
    @IBAction func publicButtonAction(_ sender: Any) {
        if room?.userList.first?.uid == Settings.loginUserId {
            changePublicStateHandler?()
        } else {
            Logger.Action.log(.room_change_state_clk, categoryValue: room?.topicId)
            self.containingController?.view.raft.autoShow(.text(R.string.localizable.amongChatRoomUserChangeNotesTitle()), userInteractionEnabled: false)
        }
    }

    @IBAction func leaveButtonAction(_ sender: Any) {
        leaveHandler?()
    }
    
    @IBAction func kickOffButtonAction(_ sender: Any) {
        kickOffHandler?()
    }
    @IBAction func reportButtonAction(_ sender: Any) {
        reportHandler?()
    }
    @IBAction func nextRoomButtonAction(_ sender: Any) {
        nextRoomHandler?()
    }
    
}
