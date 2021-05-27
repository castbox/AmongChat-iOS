//
//  FeedListCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 25/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FeedListCell: UITableViewCell {

    @IBOutlet weak var avatarView: AvatarImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var shareButton: BottomTitleButton!
    @IBOutlet weak var commentButton: BottomTitleButton!
    @IBOutlet weak var moreButton: BottomTitleButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var playerView: VideoPlayerView!
    @IBOutlet weak var pauseView: UIImageView!
    private(set) var isPlaying = false
    private(set) var liked = false
    
    private let bag = DisposeBag()
    private var emotes: [Entity.Feed] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    func config(with feed: Entity.Feed?) {
        guard let feed = feed else {
            return
        }
        avatarView.setAvatarImage(with: feed.user.pictureUrl)
        avatarView.isVerify = feed.user.isVerified
        nameLabel.attributedText = feed.user.nameWithVerified(isShowVerify: false)
        tagLabel.text = feed.topic
        playerView.configure(url: feed.url, fileExtension: "mp4", size: (feed.width ?? 100, feed.height ?? 120))
        
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        playerView.cancelAllLoadingRequest()
        resetViewsForReuse()
    }
    
    func replay(){
        if !isPlaying {
            playerView.replay()
            play()
        }
    }
    
    func play() {
        if !isPlaying {
            playerView.play()
//            musicLbl.holdScrolling = false
            isPlaying = true
        }
    }
    
    func pause(){
        if isPlaying {
            playerView.pause()
//            musicLbl.holdScrolling = true
            isPlaying = false
        }
    }
    
    func handlePause() {
        if isPlaying {
            // Pause video and show pause sign
//            UIView.animate(withDuration: 0.075, delay: 0, options: .curveEaseIn, animations: { [weak self] in
//                guard let self = self else { return }
                self.pauseView.alpha = 1
//                self.pauseView.transform = CGAffineTransform.init(scaleX: 0.45, y: 0.45)
//            }, completion: { [weak self] _ in
                self.pause()
//            })
        } else {
            // Start video and remove pause sign
//            UIView.animate(withDuration: 0.075, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
//                guard let self = self else { return }
                self.pauseView.alpha = 0
//            }, completion: { [weak self] _ in
                self.play()
//                self?.pauseView.transform = .identity
//            })
        }
    }
    
    func resetViewsForReuse(){
//        likeBtn.tintColor = .white
        pauseView.alpha = 0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        collectionView.register(nibWithCellClass: FeedEmojiCollectionCell.self)
        
        playerView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.handlePause()
            })
            .disposed(by: bag)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}


extension FeedListCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emotes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let notice = emotes.safe(indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: FeedEmojiCollectionCell.self, for: indexPath)
//            if let cell = cell as? SocialMessageCell {
//                cell.bindNoticeData(notice)
//            }
        
        return cell
    }
}

extension FeedListCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
//        guard let notice = emotes.safe(indexPath.item) else {
            return .zero
//        }

//        return notice.itemsSize
    }
    
}

extension FeedListCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let notice = emotes.safe(indexPath.item) else {
            return
        }
        
//        notice.action()
    }
    
}
