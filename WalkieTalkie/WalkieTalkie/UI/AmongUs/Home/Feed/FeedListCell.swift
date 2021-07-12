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
        case userProfile(Int)
        case follow((Bool) -> Void)
    }
    
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var userInfoContainer: UIView!
    @IBOutlet weak var avatarView: AvatarImageView!
    @IBOutlet weak var followButton: SmallSizeButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var shareButton: BottomTitleButton!
    @IBOutlet weak var commentButton: BottomTitleButton!
    @IBOutlet weak var moreButton: BottomTitleButton!
    @IBOutlet weak var emotesButton: BottomTitleButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var sliderBar: UISlider!
    @IBOutlet weak var pauseView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var videoImageView: UIImageView!
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
    private(set) var isUserPaused = false
    private(set) var viewModel: Feed.ListCellViewModel?
    private var isFullPlayed: Bool = false
    private let bag = DisposeBag()
    private var followButtonDisposable: Disposable? = nil
    
//    var listStyle: Feed.ListStyle = .recommend
    var actionHandler: ((Action) -> Void)?
    var playProgress: Float {
        isFullPlayed ? 1 : sliderBar.value
    }
    
    private var emotes: [Emote] = [] {
        didSet {
            //insert empty
            collectionView.reloadData()
        }
    }
    
    func config(with viewModel: Feed.ListCellViewModel?, listStyle: Feed.ListStyle) {
        guard let viewModel = viewModel else {
            return
        }
        self.viewModel = viewModel

        self.isUserPaused = false
        
        let feed = viewModel.feed
        avatarView.setAvatarImage(with: feed.user.pictureUrl)
        avatarView.isVerify = feed.user.isVerified
        followButtonDisposable?.dispose()
        followButtonDisposable = nil
        followButton.isSelected = false
        followButton.isHidden = feed.user.isFollowed ?? false
        
        nameLabel.attributedText = feed.user.nameWithVerified(isShowVerify: false)
        tagLabel.text = feed.topicName
        
        let feedWidth = feed.width ?? 0
        let feedHeight = feed.height ?? 0
        
        videoImageView.contentMode = feedWidth < feedHeight ? .scaleAspectFill : .scaleAspectFit

        videoImageView.setImage(with: feed.img)
        
        videoImageView.isHidden = false
        activityView.startAnimating()
        playerView.configure(url: feed.url, size: (feedWidth, feedHeight)) { [weak self] in
            self?.activityView.stopAnimating()
        }
        
        updateEmotes(with: viewModel)
        isFullPlayed = false
        sliderBar.value = 0
        
        if listStyle == .profile, Settings.loginUserId == feed.uid {
            userInfoContainer.isHidden = true
        } else {
            userInfoContainer.isHidden = false
        }
        updateCommentCount()
        updateShareCount()
    }
    
    func updateEmotes(with viewModel: Feed.ListCellViewModel) {
        self.emotes = viewModel.emotes
        if viewModel.emoteCount > 0 {
            emotesButton.setTitle(viewModel.emoteCount.string, for: .normal)
        } else {
            emotesButton.setTitle("", for: .normal)
        }
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
    
    func updateShareCount() {
        guard let feed = viewModel?.feed else {
            return
        }
        if feed.shareCountValue > 0 {
            shareButton.setTitle(feed.shareCountValue.string, for: .normal)
        } else {
            shareButton.setTitle("", for: .normal)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
//        resetViewsForReuse()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        if !backgroundLayer.frame.equalTo(gradientBackgroundView.bounds) {
//            backgroundLayer.frame = gradientBackgroundView.bounds
//            backgroundLayer.opacity = 1
//        }
    }
    
    @IBAction func followButtonAction(_ sender: UIButton) {
        guard !sender.isSelected else {
            return
        }
        
        actionHandler?(.follow({ [weak self] success in
            
            guard success else { return }
            
            sender.isSelected = true
            
            self?.followButtonDisposable = Observable.just(()).delay(.milliseconds(400), scheduler: MainScheduler.asyncInstance)
                .subscribe(onNext: { _ in
                    self?.followButton.isHidden = true
                })
        }))
        
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
    
    @IBAction func emotesButtonAction(_ sender: Any) {
        actionHandler?(.selectEmote(Entity.FeedEmote(id: "", count: 0, isVoted: false)))
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
//        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 2.1, y: 2.1)
        
        UIView.animateKeyframes(withDuration: 1.7, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.1 / 1.7) {
                view.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.1 / 1.7, relativeDuration: 0.1 / 1.7) {
                view.transform = .identity
            }
            
            UIView.addKeyframe(withRelativeStartTime: 1.5 / 1.7, relativeDuration: 0.2 / 1.7) {
                view.alpha = 0
            }
        } completion: { result in
            view.removeFromSuperview()
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
            isPlaying = true
            Logger.Action.log(.feeds_item_clk, category: .play, viewModel?.feed.pid)
            if !pauseView.isHidden {
                pauseView.fadeOut(duration: 0.1)
                sliderBar.fadeOut(duration: 0.1)
            }
        }
    }
    
    func pause(){
        if isPlaying {
            playerView.pause()
            isPlaying = false
        }
    }
    
    func handlePause() {
        if isPlaying {
            pauseView.fadeIn(duration: 0.1)
            sliderBar.fadeIn(duration: 0.1)
            isUserPaused = true
            pause()
            //手动暂停
            Logger.Action.log(.feeds_item_clk, category: .pause, viewModel?.feed.pid)
        } else {
            isUserPaused = false
            play()
        }
    }
    
//    func resetViewsForReuse() {
//        pauseView.alpha = 0
//    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                ()
                pause()
            case .moved:
                bottomBar.isHidden = true
                playerView.set(progress: slider.value.cgFloat)
                
            case .ended:
                Logger.Action.log(.feeds_item_clk, category: .slide_play, self.viewModel?.feed.pid)
                bottomBar.isHidden = false
//                play()
                handlePause()
            default:
                break
            }
        }
        progressLabel.isHidden = !bottomBar.isHidden
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
        contentView.backgroundColor = "121212".color()
        collectionView.register(nibWithCellClass: FeedEmojiCollectionCell.self)

        sliderBar.setMinimumTrackImage(UIImage.image(with: .white, size: CGSize(width: 10, height: 3)), for: .normal)
        sliderBar.setMaximumTrackImage(UIImage.image(with: UIColor.white.alpha(0.1), size: CGSize(width: 10, height: 3)), for: .normal)
        sliderBar.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        sliderBar.setThumbImage(R.image.iconFeedSliderThumb(), for: .normal)
        
        addTitleShadow(for: shareButton)
        addTitleShadow(for: commentButton)
        addTitleShadow(for: emotesButton)
        
        avatarView.clipsToBounds = false
        avatarView.verifyIV.snp.makeConstraints { maker in
            maker.top.equalTo(-1)
            maker.trailing.equalTo(4)
        }
        
        avatarView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let uid = self?.viewModel?.feed.uid else {
                    return
                }
                Logger.Action.log(.feeds_item_clk, category: .profile, self?.viewModel?.feed.pid)
                self?.actionHandler?(.userProfile(uid))
//                Routes.handle("/profile/feeds/\(uid)?index=2")
            })
            .disposed(by: bag)
        
        followButton.setBackgroundImage(UIColor(hex6: 0xFFF000).image, for: .normal)
        followButton.setBackgroundImage(UIColor(hex6: 0xFFFFFF).image, for: .selected)
        
        playerView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.handlePause()
            })
            .disposed(by: bag)
        
        playerView.playingProgressHandler = { [weak self] value in
            if value > 0 {
                self?.videoImageView.isHidden = true
            }
            self?.sliderBar.setValue(value, animated: true)
            self?.updateTimeString(with: value.double)
            if value > 0.9 {
                self?.isFullPlayed = true
                self?.actionHandler?(.playComplete)
            }
        }

        contentView.insertSubview(gradientBackgroundView, aboveSubview: playerView)
        
        backgroundLayer.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: Frame.Screen.height - Frame.Height.bottomBar)

        backgroundLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundLayer.endPoint = CGPoint(x: 0, y: 1)
        backgroundLayer.locations = [0.75, 1]
        backgroundLayer.colors = [UIColor.black.alpha(0).cgColor, UIColor.black.alpha(0.25).cgColor]
//        backgroundLayer.opacity = 0
        
        gradientBackgroundView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

    }
    
    func addTitleShadow(for button: UIButton) {
        button.titleLabel?.layer.shadowOpacity = 0.2
        button.titleLabel?.layer.shadowRadius = 2
        button.titleLabel?.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.setTitleShadowColor(.black, for: .normal)
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
