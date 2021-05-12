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
            let layout = Giphy.GifViewLayout()
            layout.delegate = self
            //            layout.scrollDirection = .vertical
            //            var hInset: CGFloat = 20
            //            var columns: Int = 1
            //            let interitemSpacing: CGFloat = 20
            //            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 84)
            //            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 0, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            //            v.register(nibWithCellClass: ConversationListCell.self)
            v.register(cellWithClass: Cell.self)
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
                maker.height.equalTo(65.5)
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
            }
            
            collectionView.pullToRefresh { [weak self] in
                self?.loadData()
            }
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
                    cdPrint("medias: \(medias)")
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
            //            let skipMS = dataSource.last?.opTime ?? 0
            
            //            Request.groupLivedataSource(groupId, skipMs: skipMS)
            //                .subscribe(onSuccess: { [weak self](data) in
            ////                    guard let data = data else { return }
            //                    let list =  data.list
            //                    var origenList = self?.dataSource
            //                    list.forEach({ origenList?.append($0)})
            //                    self?.dataSource = origenList ?? []
            //                    self?.collectionView.endLoadMore(data.more)
            //                }, onError: { (error) in
            //                    cdPrint("followingList error: \(error.localizedDescription)")
            //                }).disposed(by: bag)
        }
        
        private func searchGifs(_ key: String?) {
            guard let key = key, !key.isEmpty else {
                type = .treading
                return
            }
            type = .search
            let removeBlock = view.raft.show(.loading)
            Request.gifSearch(key: key)
                .subscribe(onSuccess: { [weak self] medias in
                    cdPrint("medias: \(medias)")
                    removeBlock()
                    guard let `self` = self else { return }
                    self.dataSource = medias ?? []
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
        cell.imageView.setImage(with: dataSource.safe(indexPath.item)?.previewGifUrl)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right + 10)) / 2
        return CGSize(width: itemSize, height: itemSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let media =  dataSource.safe(indexPath.item) else {
            return
        }
        selectAction?(media)
        dismiss(animated: true, completion: nil)
    }
}

extension Giphy.GifsViewController: GiphyGifViewLayoutDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
        return dataSource[indexPath.item].height
    }
}


extension Giphy.GifsViewController {
    
    class Cell: UICollectionViewCell {
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
            contentView.addSubviews(views: imageView)
            
            imageView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
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
