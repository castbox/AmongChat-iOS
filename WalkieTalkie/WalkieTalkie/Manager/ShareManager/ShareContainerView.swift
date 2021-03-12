//
//  ShareContainerView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
//import TikTokOpenSDK
//import EasyTipView
import RxSwift
import RxCocoa
import SwifterSwift

class ShareView: UIView, UIGestureRecognizerDelegate {
    private let bag = DisposeBag()
    private var contentView: ShareContainerView!
    private var isAutomaticShow: Bool = false
    
//    static func showWith(channel: Room, shareButton: UIButton, isAutomaticShow: Bool) {
//        let shareView = ShareView(frame: Frame.Screen.bounds, forView: shareButton)
//        shareView.alpha = 0
//        shareView.set(channel)
//        shareView.isAutomaticShow = isAutomaticShow
//        shareButton.parentViewController?.view.addSubview(shareView)
//        shareView.fadeIn(duration: AnimationDuration.fast.rawValue)
//    }
    
    init(frame: CGRect, forView: UIView) {
        super.init(frame: frame)
        
        contentView = ShareContainerView(frame: CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width - 40 * 2, height: 118)))
        addSubview(contentView)
        
        let viewController = forView.parentViewController
        let refViewFrame = forView.convert(forView.bounds, to: viewController!.view)
        contentView.top = refViewFrame.origin.y + refViewFrame.height
        contentView.left = 40
        contentView.isAutomaticShow = isAutomaticShow
        contentView.completionHandler = { [weak self] in
            self?.hideView()
        }
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        tapGesture.rx.event
            .filter { $0.state == .ended }
            .subscribe(onNext: { [weak self] _ in
//                self?.removeFromSuperview()
                guard let `self` = self else { return }
                self.hideView()
            })
            .disposed(by: bag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    func set(_ channel: Room) {
//        contentView.set(channel)
//    }
    
    func hideView() {
       self.fadeOut(duration: AnimationDuration.fast.rawValue, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }
 
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else {
            return true
        }
        return !view.isDescendant(of: contentView)
    }
}

class ShareContainerView: XibLoadableView {
        
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var isAutomaticShow: Bool = false

    private var source: [Item] = []
//    private var channel: Room!
    var completionHandler: (() -> Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateSource()
        collectionView.backgroundColor = .clear
        collectionView.register(cellWithClass: Cell.self)
        mainQueueDispatchAsync(after: 0.2) { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        return true
//    }
    
//    func set(_ channel: Room) {
//        self.channel = channel
//        titleLabel.text = "Invite Friends to \(channel.name.showName)"
//    }
    
    func updateSource() {
//        ShareManager.ShareType.allCases
//            .filter { $0.isAppInstalled }
//            .forEach { type in
//                switch type {
//                case .message:
//                    source.append(Item(icon: R.image.icon_share_message(), type: .message))
//                case .whatsapp:
//                    source.append(Item(icon: R.image.icon_share_whatsapp(), type: .whatsapp))
//                case .snapchat:
////                    let isInreview = FireStore.shared.appConfigSubject.value?.isSnapchatInreview ?? false
////                    if !isInreview {
//                        source.append(Item(icon: R.image.icon_share_snapchat(), type: .snapchat))
////                    }
//                case .ticktock:
//                    ()
////                    source.append(Item(icon: R.image.icon_share_ticktock(), type: .ticktock))
//                case .more:
//                    source.append(Item(icon: R.image.icon_share_more(), type: .more))
//                }
//        }
    }
}

extension ShareContainerView {
    
    struct Item {
        let icon: UIImage?
        let type: ShareManager.ShareType
    }
    
    class Cell: UICollectionViewCell {
        var imageView: UIImageView!
        var loadingContainer: UIView!
        var activity: UIActivityIndicatorView!
        
        var isAnimate: Bool = false {
            didSet {
                if isAnimate {
                    activity.startAnimating()
                    loadingContainer.fadeIn()
                } else {
                    activity.stopAnimating()
                    loadingContainer.fadeOut()
                }
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            
            imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            contentView.addSubview(imageView)
            imageView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            
            loadingContainer = UIView()
            loadingContainer.backgroundColor = UIColor.black.alpha(0.5)
            loadingContainer.isHidden = true
            loadingContainer.cornerRadius = 10
            contentView.addSubview(loadingContainer)
            loadingContainer.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            
            activity = UIActivityIndicatorView(style: .white)
            activity.hidesWhenStopped = true
            loadingContainer.addSubview(activity)
            activity.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension ShareContainerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return source.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: Cell.self, for: indexPath)
        if let item = source.safe(indexPath.item) {
            cell.imageView.image = item.icon
        }
        return cell
    }
}

extension ShareContainerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //select
//        guard let cell = collectionView.cellForItem(at: indexPath) as? Cell,
//            let item = source.safe(indexPath.item),
//            let channel = self.channel else {
//                return
//        }
//        self.isUserInteractionEnabled = false
//        cell.isAnimate = true
//        Logger.Share.log(.share, category: item.type.rawValue, isAutomaticShow.int.string)
//        ShareManager.default.share(with: channel.name, type: item.type, viewController: self.parentViewController!) { [weak self] in
//            self?.isUserInteractionEnabled = true
//            cell.isAnimate = false
//            self?.completionHandler?()
//        }
    }
}
