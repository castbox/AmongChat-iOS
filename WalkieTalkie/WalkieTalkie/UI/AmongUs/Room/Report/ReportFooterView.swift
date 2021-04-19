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

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var reportHeight: NSLayoutConstraint!
    
    @IBOutlet weak var uploadTitleLabel: UILabel!
    @IBOutlet weak var uploadSubtitleLabel: UILabel!
    var images: [Report.ImageItem] = []
    
    var selectImageHandler: () -> Void = { }
    var reportHandler: (String, [UIImage]) -> Void = { _, _ in }
    
    private let placeholderItem = Report.ImageItem(image: nil)
    
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        collectionView.register(nibWithCellClass: ReportImageCell.self)
        
        images.append(placeholderItem)
                
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
//            collectionView.backgroundColor = .clear
//
//            if App.group == .viviChat {
//                setReportNewStyle()
//            }
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        collectionView.reloadData()
    }
    
    @IBAction func repotAction(_ sender: Any) {
        self.reportHandler(textView.text, images.compactMap { $0.image })
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
extension ReportFooterView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

extension ReportFooterView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: ReportImageCell.self, for: indexPath)
        cell.set(images.safe(indexPath.item))
        cell.removeHandler = { [weak self] in
            self?.removeImage(indexPath.item)
        }
        return cell
    }
}

extension ReportFooterView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard images.safe(indexPath.item)?.image == nil else {
            return
        }
        selectImageHandler()
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
        collectionView.reloadData()
    }
}
