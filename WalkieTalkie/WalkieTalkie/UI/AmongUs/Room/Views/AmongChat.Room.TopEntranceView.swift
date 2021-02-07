//
//  AmongChat.Room.TopEntranceView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 02/02/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVGAPlayer
import SwiftyUserDefaults

infix operator ~>: AdditionPrecedence

@discardableResult
func ~>(left: UIViewPropertyAnimator, right: UIViewPropertyAnimator) -> UIViewPropertyAnimator{

    left.addCompletion { (_) in
        right.startAnimation()
    }

    return right
}

extension AmongChat.Room {
    class TopEntranceView: UIView {
        //queue
        private let queue = AmongChat.Room.QueueManager<Entity.RoomUser>()
        private var contentView: RoomTopEntranceContentView!
        
        override init(frame: CGRect) {
            super.init(frame: frame)

            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func add(_ user: Entity.RoomUser) {
            queue.enqueue(user) { [weak self] user in
                //play
                self?.playAnimate(with: user)
            }
        }
        
        func playAnimate(with user: Entity.RoomUser) {
            contentView.bind(with: user)
            
            let enterAnimator = UIViewPropertyAnimator(duration: 0.8, dampingRatio: 1, animations: { [weak self] in
                self?.contentView.left = 0
            })
            let leaveAnimator = UIViewPropertyAnimator(duration: AnimationDuration.slow.rawValue, dampingRatio: 1, animations: { [weak self] in
                self?.contentView.left = -Frame.Screen.width
            })
            
            leaveAnimator.addCompletion { [weak self] _ in
                self?.contentView.left = Frame.Screen.width
                self?.queue.onComplete()
            }
            enterAnimator.addCompletion { _ in
                //svga 时间长
                leaveAnimator.startAnimation(afterDelay: 1.5)
            }
//            enterAnimator ~> leaveAnimator
            enterAnimator.startAnimation()
        }
        
        private func bindSubviewEvent() {
            
        }
        
        private func configureSubview() {
            clipsToBounds = true
            contentView = RoomTopEntranceContentView()
            contentView.frame = CGRect(x: Frame.Screen.width, y: 0, width: Frame.Screen.width, height: 44)
            addSubview(contentView)
            
        }
        
    }
}

class RoomTopEntranceContentView: XibLoadableView {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var svgaView: SVGAPlayer!
    //backgroud
    private var gradient: CAGradientLayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bind(with user: Entity.RoomUser) {
        avatarImageView.setAvatarImage(with: user.pictureUrl)
        //
        let attrString = NSMutableAttributedString(attributedString: user.nameWithVerified())
        attrString.yy_appendString(" " + R.string.localizable.chatroomMessageUserJoined())
        contentLabel.attributedText = attrString
        let rect = attrString.boundingRect(with: CGSize(width: Frame.Screen.width - 70 - 74, height: 24), options: [], context: nil)
        //calculate size
        gradient.frame = CGRect(x: 20, y: 0, width: 70 + 74 + rect.width, height: 44)
        
        //get svga
        if let item = Entity.DecorationEntity.entityOf(id: user.decoPetId),
           let url = URL(string: item.url) {
            //svga
            playSvga(url)
            Logger.Action.log(.enter_room_show_pet, item.id.string)
        }
    }
    
    func playSvga(_ resource: URL?) {
        guard let resource = resource else {
            return
        }
        let parser = SVGAGlobalParser.defaut
        parser.parse(with: resource,
                     completionBlock: { [weak self] (item) in
                        self?.svgaView.videoItem = item
                        self?.svgaView.startAnimation()
                     },
                     failureBlock: { error in
                        debugPrint("error: \(error?.localizedDescription ?? "")")
                     })
    }
    
    private func bindSubviewEvent() {
        
    }
    
    override func layoutSubviews() {
//        gradient.frame = containerView.frame
    }
    
    private func configureSubview() {
        backgroundColor = .clear
        
        svgaView.clearsAfterStop = true
//        svgaView.delegate = self
        svgaView.loops = 0
        svgaView.contentMode = .scaleAspectFill
        svgaView.isUserInteractionEnabled = false
        
        gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [#colorLiteral(red: 0.3490196078, green: 0.1764705882, blue: 1, alpha: 1).cgColor, #colorLiteral(red: 0.3490196078, green: 0.1764705882, blue: 1, alpha: 1).cgColor, #colorLiteral(red: 0.3490196078, green: 0.1764705882, blue: 1, alpha: 0).cgColor]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient?.cornerRadius = 22
        gradient?.masksToBounds = true
        layer.insertSublayer(gradient!, at: 0)

    }
    
}
