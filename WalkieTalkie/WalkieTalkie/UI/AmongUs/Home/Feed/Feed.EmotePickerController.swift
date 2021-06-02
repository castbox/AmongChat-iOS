//
//  Feed.EmotePickerController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
//import Adjust

extension Feed {
    typealias FeedEmotes = Entity.GlobalSetting.Emotes
    
    class EmotePickerController: WalkieTalkie.ViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
        var collectionView: UICollectionView!
        var pageControl: UIPageControl!
        
        let viewModel: EmotePickerViewModel
        
        var didSelectItemHandler: (FeedEmotes) -> Void = { _  in }
        
        init(_ viewModel: EmotePickerViewModel) {
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)
        }
//
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor(hex: 0x303030)
            
            Logger.Action.log(.emotes_imp)

            setUpSubviews()
            configureSubview()
        }
        
        private func setUpSubviews() {
            collectionView = UICollectionView(frame: .zero, collectionViewLayout: EmojiFlowLayout())
            collectionView.backgroundColor = .clear
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.showsVerticalScrollIndicator = false
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.register(EmoteCell.self, forCellWithReuseIdentifier: NSStringFromClass(EmoteCell.self))
            collectionView.register(EmojiHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: EmojiHeaderView.className)
            collectionView.register(EmojiHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: EmojiHeaderView.className)
            collectionView.isPagingEnabled = true

            view.addSubview(collectionView)
            collectionView.snp.makeConstraints { make in
                make.top.equalTo(40)
                make.left.right.equalToSuperview()
                make.height.equalTo(viewModel.sheetHeight)
            }
            
            pageControl = UIPageControl()
            pageControl.currentPageIndicatorTintColor = .white
            pageControl.pageIndicatorTintColor = UIColor(hex: 0x666666)
            view.addSubview(pageControl)
            pageControl.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(collectionView.snp.bottom).offset(5)
            }
        }
        
        func reloadData() {
            collectionView.reloadData()
        }
        
        func configureSubview() {
            viewModel.dataSourceSubject
                .asObservable()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] items in
                    self?.pageControl.currentPage = 0
                    self?.pageControl.numberOfPages = items.count
                    self?.collectionView.reloadData()
                })
                .disposed(by: bag)
        }
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return viewModel.dataSource.count
        }
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return viewModel.dataSource[section].count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(EmoteCell.self), for: indexPath) as! EmoteCell
            cell.item = viewModel.dataSource[indexPath.section][indexPath.item]
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let item = self.viewModel.dataSource[indexPath.section][indexPath.item]

            Logger.Action.log(.emotes_item_clk, category: nil, item.id)

            hideModal(animated: true) { [weak self] in
                self?.didSelectItemHandler(item)
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: EmojiHeaderView.className, for: indexPath)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            pageControl.currentPage = {
                var index = Int((scrollView.contentOffset.x + scrollView.bounds.width / 2) / scrollView.bounds.width)
                if index > viewModel.dataSource.count {
                    index = viewModel.dataSource.count
                } else if index < 0 {
                    index = 0
                }
                return index
            }()
        }
    }
    
    class EmoteCell: UICollectionViewCell {
        
        var iconView = UIImageView()
        var titleLabel = UILabel()
        var item: FeedEmotes? {
            didSet {
                guard let item = item else {
                    return
                }
                if item.id.isEmpty {
                    iconView.image = nil
                } else {
                    iconView.setImage(with: item.img)
                }
//                iconView.alpha = item.isEnable ? 1 : 0.5
            }
        }
        
        var didTapHandler: () -> Void = { }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            contentView.addSubview(iconView)
            contentView.addSubview(titleLabel)
            titleLabel.textAlignment = .center
            titleLabel.textColor = .white
            titleLabel.font = UIFont.systemFont(ofSize: 12)
            iconView.snp.makeConstraints { make in
                make.top.equalTo(0)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(48)
            }
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(self.iconView.snp.bottom).offset(8)
                make.centerX.equalToSuperview()
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    class EmojiHeaderView: UICollectionReusableView {
        
    }
    
    class EmojiFlowLayout: UICollectionViewLayout {
        private var allItemAttribuates: [UICollectionViewLayoutAttributes] = []
        private var sectionItemAttribuates: [[UICollectionViewLayoutAttributes]] = []
        
        override func prepare() {
            super.prepare()
            guard let collectionView = collectionView else { return }
            
            let sectionCount = collectionView.numberOfSections
            if sectionCount == 0 {
                return
            }
            allItemAttribuates.removeAll()
            sectionItemAttribuates.removeAll()
            let viewWidth = collectionView.frame.width
            
            for i in 0..<sectionCount {
                let minItemSpace: CGFloat = 0
                let minLineSpace: CGFloat = 0
                
                let columnCount = 5
                let itemCount = collectionView.numberOfItems(inSection: i)
                let sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
                
                var sectionAttributes: [UICollectionViewLayoutAttributes] = []
                for j in 0 ..< itemCount {
                    
                    let indexPath = IndexPath(item: j, section: i)
                    let itemSize = CGSize(width: (UIScreen.main.bounds.size.width - sectionInset.left * 2) / (Frame.isPad ? 10 : 5), height: 64)
                    //判断列/
                    let columenIndex = j % columnCount
                    let xOffset = CGFloat(i) * viewWidth + sectionInset.left + CGFloat(columenIndex) * (itemSize.width + minLineSpace)
                    //
                    let lineIndex = j / columnCount
                    
                    let yOffset = sectionInset.top + CGFloat(lineIndex) * (itemSize.height + minItemSpace)
                    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                    attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemSize.width, height: itemSize.height)
                    sectionAttributes.append(attributes)
                    allItemAttribuates.append(attributes)
                }
                sectionItemAttribuates.append(sectionAttributes)
            }
            
        }
        
        override var collectionViewContentSize: CGSize {
            guard let collectionView = collectionView else { return .zero }
            let sectionCount = collectionView.numberOfSections
            return CGSize(width: CGFloat(UIScreen.main.bounds.width * CGFloat(sectionCount)), height: collectionView.frame.height)
        }
        
        override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
            var layoutAttributes: [UICollectionViewLayoutAttributes] = []
            for attributes in allItemAttribuates {
                if attributes.frame.intersects(rect) {
                    layoutAttributes.append(attributes)
                }
            }
            return layoutAttributes
        }
        override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
            return itemAttributes(at: indexPath)
        }
        
        override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
            return false
        }
        
        func itemAttributes(at indexPath: IndexPath?) -> UICollectionViewLayoutAttributes? {
            guard let indexPath = indexPath else { return nil }
            if indexPath.section >= sectionItemAttribuates.count {
                return nil
            }
            let sectionAttrbutes = sectionItemAttribuates[indexPath.section]
            if (indexPath.item) >= (sectionAttrbutes.count) {
                return nil
            }
            return sectionAttrbutes[indexPath.item]
        }
        
    }
}


extension Feed.EmotePickerController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 227 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    override func cornerRadius() -> CGFloat {
        return 0
    }
    
    func coverAlpha() -> CGFloat {
        return 0
    }
}
