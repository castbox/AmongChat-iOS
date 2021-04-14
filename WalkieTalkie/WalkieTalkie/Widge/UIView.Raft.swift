//
//  UIView.Raft.swift
//  Castbox
//
//  Created by ChenDong on 2017/8/23.
//  Copyright © 2017年 Guru. All rights reserved.
//

import UIKit
import MBProgressHUD

public final class Raft<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol RaftCompatible { }

public extension RaftCompatible {
    var raft: Raft<Self> {
        get { return Raft(self) }
    }
}

extension UIView: RaftCompatible {}

extension Raft where Base: UIView {
    
    typealias RemoveBlock = () -> Void

    enum ShowType {
        case loading
        case text(String)
        case doing(String)
    }
    
    func show(_ type: ShowType, graceTime: TimeInterval = 0, userInteractionEnabled: Bool = true, hideAnimated: Bool = true, offset: CGPoint = .zero) -> RemoveBlock {
        
//        switch type {
//        case .loading:
//            let loadingView = Loading(view: self.base, offset: offset)
//            return loadingView.removeBlock
//        default:
            MBProgressHUD.hide(for: self.base, animated: false)
        
            let hud = hudFor(type: type)
            hud.isUserInteractionEnabled = userInteractionEnabled
            hud.offset = offset
            
            hud.graceTime = graceTime
            hud.show(animated: true)
            return { hud.hide(animated: hideAnimated) }
//        }
    }
    
    func autoShow(_ type: ShowType, interval: TimeInterval = 2,
                  userInteractionEnabled: Bool = true,
                  backColor: UIColor? = nil,
                  completion: (() -> Void)? = nil) {
        
        MBProgressHUD.hide(for: self.base, animated: false)
        let hud = hudFor(type: type, backColor: backColor)
        hud.isUserInteractionEnabled = userInteractionEnabled
        hud.show(animated: true)
        hud.hide(animated: true, afterDelay: interval > 0 ? interval : 2)
        hud.label.numberOfLines = 0
        hud.completionBlock = completion
    }
    
    func autoHide() {
        MBProgressHUD.hide(for: self.base, animated: true)
    }
    
    func topHud() -> MBProgressHUD? {
        return MBProgressHUD(for: self.base)
    }
    
    private func hudFor(type: ShowType, backColor: UIColor? = nil) -> MBProgressHUD {
        let hud = MBProgressHUD(view: self.base)
        hud.removeFromSuperViewOnHide = true
//        hud.offset = CGPoint(x: 0, y: -base.bounds.height * 0.1)
        if let backColor = backColor {
            hud.bezelView.color = backColor
        } else {
            hud.bezelView.color = "222222".color()
        }
        hud.bezelView.style = .solidColor
        hud.margin = 16
        hud.bezelView.layer.cornerRadius = 12
        switch type {
        case .loading:
            hud.contentColor = .theme(.main)
            hud.mode = .customView
            hud.customView = Loading.RaftLoadingView()
        case let .doing(text):
            hud.contentColor = .theme(.main)
            hud.label.text = text
        case .text(let text):
            hud.mode = .text
            hud.label.text = text
            hud.label.textColor = .white
            hud.label.font = R.font.nunitoExtraBold(size: 16)
        }
        base.addSubview(hud)
        return hud
    }
}

//extension Raft where Base: LoadingButton {
//
//    func showLoading() -> RemoveBlock {
//        self.base.indicator.startAnimating()
//        return {
//            self.base.indicator.stopAnimating()
//        }
//    }
//}
//
//extension Raft where Base: InteractiveButton {
//
//    func showLoading() -> RemoveBlock {
//        self.base.showLoading(true)
//        return {
//            self.base.showLoading(false)
//        }
//    }
//}


struct Loading {
    
    let removeBlock: ()->()
    
    init(view: UIView, offset: CGPoint = .zero) {
        
        let loadingView = RaftLoadingView()
        view.addSubview(loadingView)
        
        loadingView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(offset.y)
            make.centerX.equalToSuperview().offset(offset.x)
            make.width.equalTo(UIScreen.main.bounds.width)
            make.height.equalTo(Size.singleTextCellHeight)
        }
        
        removeBlock = {
            loadingView.indicator.stopAnimating()
            loadingView.removeFromSuperview()
        }
    }
}

extension Loading {
    
    class RaftLoadingView: UIView {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            layout()
            
            indicator.startAnimating()
            
            //size
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
            cdPrint("indicator:deinit")
        }
        
        private func layout() {
            
            let layoutGuide = UILayoutGuide()
            
            addLayoutGuide(layoutGuide)
            addSubview(indicator)
            addSubview(titleLabel)
            
            layoutGuide.snp.makeConstraints { (make) in
                make.top.leading.bottom.equalTo(indicator)
                make.trailing.equalTo(titleLabel)
                make.centerX.centerY.equalToSuperview()
            }
            
            indicator.snp.makeConstraints { (make) in
                make.top.leading.equalTo(layoutGuide)
                make.size.equalTo(Size.loadingSize)
            }
            
            titleLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(indicator)
                make.leading.equalTo(indicator.snp.trailing).offset(Padding.imageTitleMarginH)
                make.trailing.equalTo(layoutGuide)
            }
        }
        
        override var intrinsicContentSize: CGSize {
            //update frame
            let width = Padding.imageTitleMarginV + Size.loadingSize.width + Padding.imageTitleMarginH + titleLabel.textSize().width + Padding.imageTitleMarginV
            let height = titleLabel.textSize().height
            self.bounds = CGRect(x: 0, y: 0, width: width, height: height)
            return bounds.size
        }
        
        lazy var indicator: UIActivityIndicatorView = {
            let indicator: UIActivityIndicatorView
//            switch Settings.shared.theme.value {
//            case .light:
//                indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
//            case .dark:
                indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
//            }
            indicator.hidesWhenStopped = false
            return indicator
        }()
        
        private lazy var titleLabel: UILabel = {
            let label = UILabel(frame: .zero)
            label.textColor = .white
            label.font = R.font.nunitoExtraBold(size: 16)
            label.text = NSLocalizedString("Loading", comment: "")
            return label
        }()
    }
}
