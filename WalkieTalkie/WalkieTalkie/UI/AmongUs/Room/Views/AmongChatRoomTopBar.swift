//
//  AmongChatRoomTopBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class BottomTitleButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        centerTitleLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centerTitleLabel()
    }
    
    private func centerTitleLabel() {
        self.titleLabel?.textAlignment = .center
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        if let image = imageView?.image {
            var labelHeight: CGFloat = 0.0
            if let size = titleLabel?.sizeThatFits(CGSize(width: self.contentRect(forBounds: self.bounds).width, height: CGFloat.greatestFiniteMagnitude)) {
                labelHeight = size.height
            }   
            return CGSize(width: size.width, height: image.size.height + labelHeight + 5)
        }
        return size
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.imageRect(forContentRect: contentRect)
        let titleRect = self.titleRect(forContentRect: contentRect)
        
        return CGRect(x: contentRect.width/2.0 - rect.width/2.0,
                      y: (contentRect.height - titleRect.height)/2.0 - rect.height/2.0,
                      width: rect.width, height: rect.height)
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.titleRect(forContentRect: contentRect)
        return CGRect(x: 0, y: contentRect.height - rect.height, width: contentRect.width, height: rect.height)
    }
}

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
        if room?.roomUserList.first?.uid == Settings.loginUserId {
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
