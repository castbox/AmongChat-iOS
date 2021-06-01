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

extension Feed {
    struct FeedEmoteCellViewModel {
        let emote: Entity.GlobalSetting.Emotes
        let width: CGFloat
        
        init(emote: Entity.GlobalSetting.Emotes,
             width: CGFloat) {
            self.emote = emote
            self.width = width //
            
        }
    }
}

class FeedListCell: UITableViewCell {
    
    typealias Emote = Entity.FeedEmote
    
    enum Action {
        case selectEmote(Emote) //id
        case share
        case comment
        case more
        case playComplete
    }
    
    @IBOutlet weak var userInfoContainer: UIView!
    @IBOutlet weak var avatarView: AvatarImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var shareButton: BottomTitleButton!
    @IBOutlet weak var commentButton: BottomTitleButton!
    @IBOutlet weak var moreButton: BottomTitleButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var sliderBar: UISlider!
    @IBOutlet weak var pauseView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var progressLabel: UILabel!
    
    private lazy var backgroundLayer = CAGradientLayer()
    private lazy var gradientBackgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.layer.insertSublayer(backgroundLayer, at: 0)
        return view
    }()

    
    private(set) var isPlaying = false
    private(set) var liked = false
    
    
    private let bag = DisposeBag()
    
    private(set) var viewModel: Feed.ListCellViewModel?
    var actionHandler: ((Action) -> Void)?
    
    private var emotes: [Emote] = [] {
        didSet {
            //insert empty
            collectionView.reloadData()
        }
    }
    
    func config(with viewModel: Feed.ListCellViewModel?) {
        self.viewModel = viewModel
        guard let viewModel = viewModel else {
            return
        }
        let feed = viewModel.feed
        avatarView.setAvatarImage(with: feed.user.pictureUrl)
        avatarView.isVerify = feed.user.isVerified
        nameLabel.attributedText = feed.user.nameWithVerified(isShowVerify: false)
        tagLabel.text = feed.topicName
        
        activityView.startAnimating()
        playerView.configure(url: feed.url, size: (feed.width ?? 100, feed.height ?? 120)) { [weak self] in
            self?.activityView.stopAnimating()
        }
        update(emotes: viewModel.emotes)
        if feed.cmtCount > 0 {
            commentButton.setTitle(feed.cmtCount.string, for: .normal)
        } else {
            commentButton.setTitle("", for: .normal)
        }
        
        if feed.shareCountValue > 0 {
            shareButton.setTitle(feed.shareCountValue.string, for: .normal)
        } else {
            shareButton.setTitle("", for: .normal)
        }
        updateCommentCount()
    }
    
    func update(emotes: [Emote]) {
        self.emotes = emotes
    }
    
    func updateCommentCount() {
        guard let feed = viewModel?.feed else {
            return
        }
        if feed.cmtCount > 0 {
            commentButton.setTitle(feed.cmtCount.string, for: .normal)
        } else {
            commentButton.setTitle("", for: .normal)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        playerView.cancelAllLoadingRequest()
        resetViewsForReuse()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = gradientBackgroundView.bounds
    }
    
    @IBAction func commentButtonAction(_ sender: Any) {
        actionHandler?(.comment)
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        actionHandler?(.share)
    }
    
    @IBAction func moreButtonAction(_ sender: Any) {
        actionHandler?(.more)
    }
    
    @IBAction func sliderEndDragAction(_ sender: Any) {
        avatarView.isHidden = false
    }
    
    func show(emote: Emote?) {
        guard let emote = emote else {
            return
        }
        
        let view = UIImageView()
        view.setImage(with: emote.img)
        contentView.addSubview(view)
        //widht
        let emoteSize: CGFloat = 100
        let leftEdge: CGFloat = 20
        let maxX = width - 100 - leftEdge
        let xOffset = Int(arc4random()) % maxX.int
        let y = height / 4 + (Int(arc4random()) % (width - emoteSize).int).cgFloat
        view.frame = CGRect(x: 20 + xOffset.cgFloat, y: y, width: emoteSize, height: emoteSize)
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.2, delay: 0.1, options: [.beginFromCurrentState, .curveEaseIn]) {
            view.alpha = 1
            view.transform = CGAffineTransform(scaleX: 2, y: 2)
        } completion: { finish in
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .curveEaseIn]) {
                view.alpha = 1
                view.transform = .identity
            } completion: { finish in
                UIView.animate(withDuration: 0.2, delay: 1.5, options: [.beginFromCurrentState, .curveEaseIn]) {
                    view.alpha = 0
                    view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                } completion: { finish in
                    view.removeFromSuperview()
                }
            }
        }
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
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                ()
            case .moved:
                userInfoContainer.isHidden = true
                pause()
                playerView.set(progress: slider.value.cgFloat)
                
            case .ended:
                userInfoContainer.isHidden = false
                play()
            default:
                break
            }
        }
        progressLabel.isHidden = !userInfoContainer.isHidden
        //calculate progress
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configureSubview()
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

private extension FeedListCell {
    func updateTimeString(with progress: Double) {
        let time = playerView.duration.double * progress
        let currentTimeAttrString = NSAttributedString(string: time.timeFormat, attributes: [
            NSAttributedString.Key.foregroundColor : UIColor.white
         ])
        let durationAttrString = NSAttributedString(string: " / \(playerView.duration.double.timeFormat)", attributes: [
            NSAttributedString.Key.foregroundColor : UIColor.white.alpha(0.5)
         ])
        let multiAttrString = NSMutableAttributedString()
        multiAttrString.append(currentTimeAttrString)
        multiAttrString.append(durationAttrString)
        
        progressLabel.attributedText = multiAttrString
    }
    
    func configureSubview() {
        collectionView.register(nibWithCellClass: FeedEmojiCollectionCell.self)
        
        sliderBar.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        sliderBar.setThumbImage(R.image.iconFeedSliderThumb(), for: .normal)
//        sliderBar.setThumbImage(R.image.iconFeedSliderThumb(), for: .)
        
        avatarView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let uid = self?.viewModel?.feed.uid else {
                    return
                }
                Routes.handle("/profile/\(uid)")
//                Routes.handle("/profile/feeds/\(uid)?index=2")
            })
            .disposed(by: bag)
        
        playerView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.handlePause()
            })
            .disposed(by: bag)
        
        playerView.playingProgressHandler = { [weak self] value in
//            cdPrint("progress: \(value)")
            self?.sliderBar.setValue(value, animated: true)
            self?.updateTimeString(with: value.double)
            if value > 0.9 {
                self?.actionHandler?(.playComplete)
            }
        }

        contentView.insertSubview(gradientBackgroundView, aboveSubview: playerView)
        
        backgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundLayer.endPoint = CGPoint(x: 0, y: 1)
        backgroundLayer.locations = [0, 0.2, 0.8, 1]
        backgroundLayer.colors = [UIColor.black.alpha(0.3).cgColor, UIColor.black.alpha(0).cgColor, UIColor.black.alpha(0).cgColor, UIColor.black.alpha(0.3).cgColor]

        gradientBackgroundView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

    }
}

extension FeedListCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emotes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: FeedEmojiCollectionCell.self, for: indexPath)
        if let emote = emotes.safe(indexPath.item) {
            cell.config(with: emote)
        }
        return cell
    }
}

extension FeedListCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let emote = emotes.safe(indexPath.item) else {
            return .zero
        }
        //notice.itemsSize
        return CGSize(width: emote.width, height: 32)
    }
    
}

extension FeedListCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let emote = emotes.safe(indexPath.item) else {
            return
        }
        
        actionHandler?(.selectEmote(emote))
    }
    
}
