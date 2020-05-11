//
//  GlobalChannelContainer.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import JXPagingView

class GlobalChannelContainer: XibLoadableView {

    @IBOutlet weak var titleLabel: WalkieLabel!
    @IBOutlet weak var descLabel: WalkieLabel!
    @IBOutlet weak var createButton: WalkieButton!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet weak var textField: ChannelNameField!
    @IBOutlet weak var bottonEdgeHeightConstraint: NSLayoutConstraint!
    
    var joinChannel: (String, Bool) -> Void = { _, _ in }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bottonEdgeHeightConstraint.constant = Frame.Height.safeAeraBottomHeight
        textField.didReturn = { [weak self] text in
            self?.joinChannel(text)
            Logger.UserAction.log(.channel_create_new, text)
        }
        
        let attributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor.black.alpha(0.3),
            .font: R.font.nunitoSemiBold(size: 15),
            .kern: 0.5,
        ]
        textField.attributedPlaceholder = NSAttributedString(string: R.string.localizable.inputPasscodeGlobalPlaceholder(), attributes: attributes)
        
        titleLabel.appendKern()
        descLabel.appendKern()
        createButton.appendKern()
        
        textField.defaultTextAttributes = [
            .kern: 0.5,
            .font: R.font.nunitoBold(size: 17),
        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
    @IBAction private func creatAction(_ sender: Any) {
        joinChannel(textField.text)
    }
    
    func joinChannel(_ channel: String?) {
        guard let channel = channel else {
            return
        }
        joinChannel(channel, false)
    }
}

extension GlobalChannelContainer: JXPagingViewListViewDelegate {
    
    public func listView() -> UIView {
        return self
    }
    
    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
//        self.listViewDidScrollCallback = callback
    }

    public func listScrollView() -> UIScrollView {
        return scrollView
    }

    public func listDidDisappear() {
        print("listDidDisappear")
    }

    public func listDidAppear() {
        print("listDidAppear")
    }
}
