//
//  AmongGroupHostView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import EasyTipView
import RxSwift
import RxCocoa

class AmongGroupHostView: XibLoadableView {
    
    @IBOutlet weak var hostView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var raiseButton: UIImageView!
    @IBOutlet weak var groupJoinButton: UIImageView!
    
    private var tipView: EasyTipView?
    let bag = DisposeBag()
//    private var userCell: AmongChat.Room.UserCell!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        bindSubviewEvent()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func showShareTipView() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = R.font.nunitoExtraBold(size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        preferences.drawing.foregroundColor = .black
        preferences.drawing.backgroundColor = .white
        preferences.drawing.arrowPosition = .bottom
        
        tipView = EasyTipView(text: "Share your livecast to the people that you want to invite",
                              preferences: preferences,
                              delegate: self)
        tipView?.tag = 0
        tipView?.show(animated: true, forView: raiseButton, withinSuperview: superview)
        Observable<Int>
            .interval(.seconds(5), scheduler: MainScheduler.instance)
            .single()
            .subscribe(onNext: { [weak welf = self] _ in
                guard let `self` = welf else { return }
                self.dismissTipView()
            })
            .disposed(by: self.bag)
    }
    
    @objc func dismissTipView() {
        tipView?.dismiss()
    }
    
    @IBAction func raisedHandsAction(_ sender: Any) {
        
    }
    
    @IBAction func joinReuqestAction(_ sender: Any) {
        
    }
    
    @IBAction func hostAvatarAction(_ sender: Any) {
        showShareTipView()
    }
    
    private func bindSubviewEvent() {
//        userCell.bind(nil, topic: .amongus, index: 0)
    }
    
    private func configureSubview() {
//        hostView?.bind(nil, topic: .amongus, index: 0)
//        userCell = AmongChat.Room.UserCell(frame: CGRect(x: 0, y: 0, width: AmongChat.Room.SeatView.itemWidth, height: AmongChat.Room.SeatView.itemHeight))
//        hostView.addSubview(userCell)
//        userCell.snp.makeConstraints { maker in
//            maker.width.equalTo(AmongChat.Room.SeatView.itemWidth)
//            maker.height.equalTo(AmongChat.Room.SeatView.itemHeight)
//            maker.center.equalToSuperview()
//        }
//        if index < 5 {
//            topStackView.addArrangedSubview(cell)
//        } else {
//            bottomStackView.addArrangedSubview(cell)
//        }
//        cell.emojisNames = room.topicType.roomEmojiNames

    }
    
}

extension AmongGroupHostView: EasyTipViewDelegate {
    func easyTipViewDidTap(_ tipView: EasyTipView) {
        dismissTipView()
    }
    
    func easyTipViewDidDismiss(_ tipView : EasyTipView) {
        
    }
}
