//
//  ReportFooterView.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/15.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReportFooterView: XibLoadableView {
//    enum Action {
//        case updateNotes(String)
//        case updateImage([UIImage])
//    }

    private var textView: UITextView!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var videosCollectionView: UICollectionView!
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var reportHeight: NSLayoutConstraint!
    
    @IBOutlet weak var uploadTitleLabel: UILabel!
    @IBOutlet weak var uploadSubtitleLabel: UILabel!
    @IBOutlet weak var imageCountLabel: UILabel!
    
    @IBOutlet weak var uploadVideoTitleLabel: UILabel!
    @IBOutlet weak var videoCountLabel: UILabel!
    
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videosCollectionViewHeight: NSLayoutConstraint!
    
    private lazy var commentInputView: FansGroup.Views.GroupDescriptionView = {
        let d = FansGroup.Views.GroupDescriptionView()
        d.placeholderLabel.text = R.string.localizable.reportCommentsPlaceholder()
        textView = d.inputTextView
        textView.keyboardDistanceFromTextField = 39
        return d
    }()
    
//    private lazy var 
        
    var selectedIndex: Int = -1 {
        didSet {
            updateReportButtonState()
        }
    }
    
    var images: [Report.ImageItem] = [] {
        didSet {
            let count = images.filter { $0.image != nil }.count
            imageCountLabel.text = "\(count)/3"
            updateReportButtonState()
        }
    }
    
    var videoItems: [Report.VideoItem] = [] {
        didSet {
            let count = videoItems.filter { $0.url != nil }.count
            videoCountLabel.text = "\(count)/\(maxVideosCount)"
            updateReportButtonState()
        }
    }
    enum MediaType {
        case image, video
    }
    var selectMediaHandler: ((MediaType) -> Void)? = nil
    var reportHandler: ((Int, String, [UIImage], [URL]) -> Void)?
    
    private let placeholderItem = Report.ImageItem(image: nil)
    private let videoPlaceholderItem = Report.VideoItem(image: nil, url: nil)
    private let maxVideosCount = Int(1)
    private let maxInputLength = Int(280)
    private let bag = DisposeBag()
    static let collectionItemWidth: CGFloat = Frame.isPad ? 180 : ((Frame.Screen.width - 20 * 2 - 16 * 2) / 3).ceil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imagesCollectionView.register(nibWithCellClass: ReportImageCell.self)
        videosCollectionView.register(nibWithCellClass: ReportImageCell.self)

        images.append(placeholderItem)
        videoItems.append(videoPlaceholderItem)
        
//        reportButton.layer.cornerRadius = 24
        reportButton.clipsToBounds = true
        reportButton.setTitleColor(.black, for: .normal)
        reportButton.setTitleColor("#757575".color(), for: .disabled)
        reportButton.setBackgroundImage("#FFF000".color().image, for: .normal)
        reportButton.setBackgroundImage("#303030".color().image, for: .disabled)

        collectionViewHeightConstraint.constant = Self.collectionItemWidth
        videosCollectionViewHeight.constant = Self.collectionItemWidth
        
        addSubview(commentInputView)
        commentInputView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.top.equalTo(commentLabel.snp.bottom).offset(16)
        }
        
        commentInputView.inputTextView.rx.text
            .subscribe(onNext: { [weak self] (_) in
                self?.updateReportButtonState()
            })
            .disposed(by: bag)

//        if Theme.currentMode == .dark {
//            backgroundColor = UIColor.theme(.backgroundWhite)
//
//            commentLabel.rx.textColor
//                .setTheme(by: .textBlack)
//                .disposed(by: bag)
//
//            textView.rx.textColor
//                .setTheme(by: .textBlack)
//                .disposed(by: bag)
//            uploadTitleLabel.rx.textColor
//                .setTheme(by: .textBlack)
//                .disposed(by: bag)
//
//            uploadSubtitleLabel.rx.textColor
//                .setTheme(by: .textLightGray)
//                .disposed(by: bag)
//
//            textView.backgroundColor = UIColor.theme(.backgroundLightGray)
        imagesCollectionView.backgroundColor = .clear
        videosCollectionView.backgroundColor = .clear
//
//            if App.group == .viviChat {
//                setReportNewStyle()
//            }
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateReportButtonState() {
        let validImageCount = images.filter { $0.image != nil }.count
        let validVideoCount = videoItems.filter { $0.url != nil }.count
        reportButton.isEnabled = selectedIndex >= 0 && (validImageCount > 0 || validVideoCount > 0) && textView.text.isValid
    }
    
    func append(image: UIImage?) {
        guard let image = image else {
            return
        }
        let item = Report.ImageItem(image: image)
        images.insert(item, at: 0)
        if images.count > 3 {
            _ = images.removeLast()
        }
        imagesCollectionView.reloadData()
    }
    
    @IBAction func repotAction(_ sender: Any) {
        self.reportHandler?(selectedIndex, textView.text, images.compactMap { $0.image }, videoItems.compactMap { $0.url })
    }
    
    func setReportNewStyle() {
//        reportButton.backgroundColor = UIColor.theme(.pinklight)
//        reportHeight.constant = 58
//        reportButton.layer.masksToBounds = true
//        reportButton.layer.cornerRadius = 29
//        reportButton.titleLabel?.font = Font.mediumTitle25.value
//        reportButton.setTitle("Report", for: .normal)
    }
    
}

extension ReportFooterView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 20, height: Self.collectionItemWidth)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Self.collectionItemWidth, height: Self.collectionItemWidth)
    }
}

extension ReportFooterView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == imagesCollectionView {
            return images.count
        } else {
            return videoItems.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == imagesCollectionView {
            let cell = collectionView.dequeueReusableCell(withClass: ReportImageCell.self, for: indexPath)
            cell.set(images.safe(indexPath.item))
            cell.removeHandler = { [weak self] in
                self?.removeImage(indexPath.item)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: ReportImageCell.self, for: indexPath)
            cell.style = .video
            cell.set(videoItems.safe(indexPath.item))
            cell.removeHandler = { [weak self] in
                self?.removeVideo(indexPath.item)
            }
            return cell
        }
    }
}

extension ReportFooterView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == imagesCollectionView {
            guard images.safe(indexPath.item)?.image == nil else {
                return
            }
            selectMediaHandler?(.image)
        } else {
            guard videoItems.safe(indexPath.item)?.url == nil else {
                return
            }
            selectMediaHandler?(.video)
        }
    }
}

extension ReportFooterView {
    func removeImage(_ index: Int) {
        guard images.count > index else {
            return
        }
        images.remove(at: index)
        if images.count < 3,
            images.last?.image != nil {
            images.append(placeholderItem)
        }
        imagesCollectionView.reloadData()
    }
    
    func removeVideo(_ index: Int) {
        guard videoItems.count > index else {
            return
        }
        videoItems.remove(at: index)
        if videoItems.count < maxVideosCount,
           (videoItems.count == 0 || videoItems.last?.image != nil) {
            videoItems.append(videoPlaceholderItem)
        }
        videosCollectionView.reloadData()
    }
    
    func append(thumbnail: UIImage, video: URL) {
        
        let item = Report.VideoItem(image: thumbnail, url: video)

        videoItems.insert(item, at: 0)
        if videoItems.count >= maxVideosCount {
            _ = videoItems.removeLast()
        }
        videosCollectionView.reloadData()
    }

}
