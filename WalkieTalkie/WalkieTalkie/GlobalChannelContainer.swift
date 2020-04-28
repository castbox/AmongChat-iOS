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

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet weak var textField: ChannelNameField!
    @IBOutlet weak var bottonEdgeHeightConstraint: NSLayoutConstraint!
    
    var joinChannel: (String, Bool) -> Void = { _, _ in }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bottonEdgeHeightConstraint.constant = Frame.Height.safeAeraBottomHeight
        textField.didReturn = { [weak self] textField in
            self?.joinChannel(textField.text)
            Logger.UserAction.log(.channel_create, textField.text?.uppercased())
        }
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
