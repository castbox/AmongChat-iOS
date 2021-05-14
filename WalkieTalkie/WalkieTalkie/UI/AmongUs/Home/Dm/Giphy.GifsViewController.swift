//
//  Conversation.GifsViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 11/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import HWPanModal
import IQKeyboardManagerSwift
import Kingfisher

struct Giphy {
    //    api_key: string(required)    YOUR_API_KEY    GIPHY API Key.
    //    limit: integer (int32)    20    The maximum number of objects to return. (Default: “25”)
    //    offset: integer (int32)    5    Specifies the starting position of the results.
    //    Default: “0”
    //    Maximum: “4999”
    //    rating: string    g    Filters results by specified rating. Acceptable values include g, pg, pg-13, r. If you do not specify a rating, you will receive results from all possible ratings.
    //    random_id: string    e826c9fc5c929e0d6c6d423841a282aa    An ID/proxy for a specific user.
}

extension Giphy {
    class GifsViewController: WalkieTalkie.ViewController {
        enum DataType {
            case treading
            case search
        }
        
        private lazy var titleView: HeaderView = {
            let v = HeaderView()
            //            v.title = R.string.localizable.groupRoomMembersTitle()
            return v
        }()
        
        private lazy var collectionView: UICollectionView = {
            let layout = WaterfallLayout()
            layout.delegate = self
            layout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
            layout.minimumLineSpacing = 12
            layout.minimumInteritemSpacing = 12
            layout.headerHeight = 50.0
            
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            //            v.register(nibWithCellClass: ConversationListCell.self)
            v.register(cellWithClass: Cell.self)
            v.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: GiphyHeaderView.self)
            //            v.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private var treadingDataSource: [Giphy.GPHMedia] = [] {
            didSet {
                dataSource = treadingDataSource
            }
        }
        
        private var searchDataSource: [Giphy.GPHMedia] = [] {
            didSet {
                dataSource = searchDataSource
            }
        }
        
        private var dataSource: [Giphy.GPHMedia] = [] {
            didSet {
                collectionView.reloadData()
                if dataSource.isEmpty {
                    addNoDataView(R.string.localizable.errorNoFollowing())
                } else {
                    removeNoDataView()
                }
            }
        }
        
        private var type: DataType = .treading {
            didSet {
                switch type {
                case .search:
                    dataSource = searchDataSource
                case .treading:
                    dataSource = treadingDataSource
                }
            }
        }
        
        private var searchKey: String?
        
        var selectAction: ((Giphy.GPHMedia) -> Void)?
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            IQKeyboardManager.shared.enable = false
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            IQKeyboardManager.shared.enable = true
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            //            view.backgroundColor = UIColor.theme(.backgroundBlack)
            view.backgroundColor = "222222".color()
            
            
            //            Logger.Action.log(.profile_following_imp, category: nil)
            
            view.addSubviews(views: titleView)
            
            titleView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(72)
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            view.addSubview(collectionView)
            collectionView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(titleView.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            titleView.searchAction = { [weak self] key in
                self?.searchGifs(key)
                Logger.Action.log(.gif_search_clk, categoryValue: key)
            }
            
            //            collectionView.pullToRefresh { [weak self] in
            //                self?.loadData()
            //            }
            collectionView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
        }
        
        override func addNoDataView(_ message: String, image: UIImage? = nil) {
            removeNoDataView()
            let v = NoDataView(with: message, image: image, topEdge: 60)
            view.addSubview(v)
            v.snp.makeConstraints { (maker) in
                maker.top.equalTo(60)
                maker.left.right.equalToSuperview()
                maker.height.equalTo(500 - 120)
            }
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            Request.gifTreading()
                .subscribe(onSuccess: { [weak self] medias in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.treadingDataSource = medias ?? []
                }, onError: { error in
                    
                })
                .disposed(by: bag)
            //            Request.groupLivedataSource(groupId, skipMs: 0)
            //                    .subscribe(onSuccess: { [weak self](data) in
            //                        removeBlock()
            //                        guard let `self` = self else { return }
            //                        self.dataSource = data.list
            ////                        self.tableView.endLoadMore(data.more)
            //                    }, onError: { [weak self](error) in
            //                        removeBlock()
            //                        self?.addErrorView({ [weak self] in
            //                            self?.loadData()
            //                        })
            //                        cdPrint("followingList error: \(error.localizedDescription)")
            //                    }).disposed(by: bag)
        }
        
        private func loadMore() {
            if type == .search {
                guard let key = searchKey else {
                    self.collectionView.endLoadMore(false)
                    return
                }
                let offset = dataSource.count
                Request.gifSearch(key: key, offset: offset)
                    .subscribe(onSuccess: { [weak self] medias in
                        //                        removeBlock()
                        guard let `self` = self, let list = medias else { return }
                        //                        self.treadingDataSource = medias ?? []
                        var originList = self.treadingDataSource
                        originList.append(contentsOf: list)
                        self.treadingDataSource = originList
                        self.collectionView.endLoadMore(true)
                    }, onError: { [weak self] error in
                        self?.collectionView.endLoadMore(false)
                    })
                    .disposed(by: bag)
            } else {
                let offset = dataSource.count
                Request.gifTreading(offset: offset)
                    .subscribe(onSuccess: { [weak self] medias in
                        //                        removeBlock()
                        guard let `self` = self, let list = medias else { return }
                        //                        self.treadingDataSource = medias ?? []
                        var originList = self.treadingDataSource
                        originList.append(contentsOf: list)
                        self.treadingDataSource = originList
                        self.collectionView.endLoadMore(true)
                    }, onError: { [weak self] error in
                        self?.collectionView.endLoadMore(false)
                    })
                    .disposed(by: bag)
                
            }
        }
        
        private func searchGifs(_ key: String?) {
            searchKey = key
            guard let key = key, !key.isEmpty else {
                type = .treading
                return
            }
            type = .search
            let removeBlock = view.raft.show(.loading)
            Request.gifSearch(key: key)
                .subscribe(onSuccess: { [weak self] medias in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.dataSource = medias ?? []
                }, onError: { error in
                    
                })
                .disposed(by: bag)
        }
    }
}
// MARK: - UICollectionViewDelegate
extension Giphy.GifsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: Cell.self, for: indexPath)
        //    cell.photo = Data[indexPath.item]
        cell.indicator.startAnimating()
        cell.imageView.setImage(with: dataSource.safe(indexPath.item)?.previewGifUrl, completionHandler: { [weak cell] _ in
            cell?.indicator.stopAnimating()
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        //        v.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: GiphyHeaderView.self)
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: GiphyHeaderView.self, for: indexPath)
        return view
    }
    
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    //        let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right + 10)) / 2
    //        return CGSize(width: itemSize, height: itemSize)
    //    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: Frame.Screen.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let media =  dataSource.safe(indexPath.item) else {
            return
        }
        selectAction?(media)
        dismiss(animated: true, completion: nil)
    }
}

extension Giphy.GifsViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let media = dataSource.safe(indexPath.item) {
            let leftEdge: CGFloat = 20
            let itemSpace: CGFloat = 12
            let itemWidth: CGFloat = ((Frame.Screen.width - leftEdge * 2 - itemSpace) / 2).floor
            return CGSize(width: itemWidth, height: media.height)
        }
        return WaterfallLayout.automaticSize //CGSize(width: 300, height: 180)
    }
    
    func collectionViewLayout(for section: Int) -> WaterfallLayout.Layout {
        return .waterfall(column: 2, distributionMethod: .balanced)
    }
    
}

//extension Giphy.GifsViewController: GiphyGifViewLayoutDelegate {
//    func collectionView(
//        _ collectionView: UICollectionView,
//        heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
//        return dataSource[indexPath.item].height
//    }
//}


extension Giphy.GifsViewController {
    
    class GiphyHeaderView: UICollectionReusableView {
        lazy var imageView: AnimatedImageView = {
            let v = AnimatedImageView()
            v.image = R.image.iconPoweredbyBlackVert()
            v.contentMode = .scaleAspectFill
            v.clipsToBounds = true
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
        }
        
        private func setupLayout() {
            addSubviews(views: imageView)
            
            imageView.snp.makeConstraints { (maker) in
                maker.left.equalTo(20)
                maker.centerY.equalToSuperview()
            }
        }
    }
    
    class Cell: UICollectionViewCell {
        lazy var indicator: UIActivityIndicatorView = {
            let v = UIActivityIndicatorView(style: .white)
            v.hidesWhenStopped = true
            return v
        }()
        
        lazy var imageView: AnimatedImageView = {
            let v = AnimatedImageView()
            v.contentMode = .scaleAspectFill
            v.clipsToBounds = true
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
        }
        
        private func setupLayout() {
            contentView.addSubviews(views: indicator, imageView)
            
            imageView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            indicator.snp.makeConstraints { maker in
                maker.center.equalTo(imageView.snp.center)
            }
        }
    }
}

extension Giphy.GifsViewController {
    
    class HeaderView: UIView {
        let bar: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.2)
            v.layer.cornerRadius = 2
            v.clipsToBounds = true
            return v
        }()
        
        private lazy var searchTextfield: Search.TextField = {
            let textfield = Search.TextField(fontSize: 20)
            textfield.delegate = self
            textfield.cornerRadius = 18
            textfield.backgroundColor = "#2D2D2D".color()
            textfield.attributedPlaceholder = NSAttributedString(string: R.string.localizable.dmGifSearchPlaceholder(), attributes: [
                NSAttributedString.Key.foregroundColor : UIColor("#646464"),
                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 20)
            ])
            return textfield
        }()
        
        var searchAction: ((String?) -> Void)?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubviews(views: bar, searchTextfield)
            
            searchTextfield.snp.makeConstraints { maker in
                maker.trailing.leading.equalToSuperview().inset(20)
                maker.height.equalTo(36)
                maker.bottom.equalTo(-12)
            }
            
            bar.snp.makeConstraints { (maker) in
                maker.top.equalTo(8)
                maker.height.equalTo(4)
                maker.width.equalTo(36)
                maker.centerX.equalToSuperview()
            }
            
            let lineView = UIView()
            lineView.backgroundColor = UIColor.white.alpha(0.08)
            addSubviews(views: lineView)
            
            lineView.snp.makeConstraints { maker in
                maker.left.right.bottom.equalToSuperview()
                maker.height.equalTo(1)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension Giphy.GifsViewController.HeaderView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let text = textField.text?.trimmed,
           text.count > 0 {
            searchAction?(text)
            
        } else {
            textField.text = nil
            searchAction?(nil)
        }
        //        Logger.Action.log(.search_done)
        //        search(key: text)
        return true
    }
}

extension Giphy.GifsViewController {
    
    override func longFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .topInset, height: 0)
    }
    
    override func shortFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: Frame.Scale.height(500))
    }
    
    override func panScrollable() -> UIScrollView? {
        return collectionView
    }
    
    override func allowsExtendedPanScrolling() -> Bool {
        return true
    }
    
    override func cornerRadius() -> CGFloat {
        return 20
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
    override func isAutoHandleKeyboardEnabled() -> Bool {
        false
    }
    
}
