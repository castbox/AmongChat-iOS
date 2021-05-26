//
//  AmongChat.Home.FeedViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 25/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import RxSwift

struct Post: Codable {
    var id: String
    var video: String
    var videoURL: URL?
    var videoFileExtension: String?
    var videoHeight: Int
    var videoWidth: Int
    var autherID: String
    var autherName: String
    var caption: String
    var music: String
    var likeCount: Int
    var shareCount: Int
    var commentID: String
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case video
        case videoURL
        case videoFileExtension
        case videoHeight
        case videoWidth
        case autherID = "author"
        case autherName
        case caption
        case music
        case likeCount
        case shareCount
        case commentID
    }
    
    init(id: String, video: String, videoURL: URL? = nil, videoFileExtension: String? = nil, videoHeight: Int, videoWidth: Int, autherID: String, autherName: String, caption: String, music: String, likeCount: Int, shareCount: Int, commentID: String) {
        self.id = id
        self.video = video
        self.videoURL = videoURL ?? URL(fileURLWithPath: "")
        self.videoFileExtension = videoFileExtension ?? "mp4"
        self.videoHeight = videoHeight
        self.videoWidth = videoWidth
        self.autherID = autherID
        self.autherName = autherName
        self.caption = caption
        self.music = music
        self.likeCount = likeCount
        self.shareCount = shareCount
        self.commentID = commentID
    }
    
    init(dictionary: [String: Any]) {
        id = dictionary["id"] as? String ?? ""
        video = dictionary["video"] as? String ?? ""
        let urlString = dictionary["videoURL"] as? String ?? ""
        videoURL = URL(string: urlString)
        videoFileExtension = dictionary["videoFileExtension"] as? String ?? ""
        videoHeight = dictionary["videoHeight"] as? Int ?? 0
        videoWidth = dictionary["videoWidth"] as? Int ?? 0
        autherID = dictionary["author"] as? String ?? ""
        autherName = dictionary["autherName"] as? String ?? ""
        caption = dictionary["caption"] as? String ?? ""
        music = dictionary["music"] as? String ?? ""
        likeCount = dictionary["likeCount"] as? Int ?? 0
        shareCount = dictionary["shareCount"] as? Int ?? 0
        commentID = dictionary["commentID"] as? String ?? ""
    }

    
    var dictionary: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .allowFragments]) as? [String: Any]) ?? [:]
    }
    
}

extension AmongChat.Home {
    
    class FeedViewController: WalkieTalkie.ViewController {
        
        var tableView: UITableView!
        
        @objc dynamic var currentIndex = 0
        var oldAndNewIndices = (0,0)
        
//        let viewModel = HomeViewModel()
        let disposeBag = DisposeBag()
        var data = [Post]()
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        // MARK: - Lifecycles
        override func viewDidLoad() {
            super.viewDidLoad()
//            viewModel.setAudioMode()
            configureSubview()
            setupBinding()
            setupObservers()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if let cell = tableView.visibleCells.first as? FeedListCell {
//                cell.play()
            }
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if let cell = tableView.visibleCells.first as? FeedListCell {
//                cell.pause()
            }
        }
        
        func configureSubview() {
            // Table View
            tableView = UITableView()
            tableView.backgroundColor = .black
            tableView.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
            tableView.tableFooterView = UIView()
            tableView.isPagingEnabled = true
//            if @available(iOS 11.0, *) {
//                tableView.contentInsetAdjustmentBehavior = .never
//            }
            tableView.showsVerticalScrollIndicator = false
            tableView.separatorStyle = .none
            view.addSubview(tableView)
            tableView.snp.makeConstraints({ make in
                make.edges.equalToSuperview()
            })
            tableView.register(nibWithCellClass: FeedListCell.self)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.prefetchDataSource = self
        }

        /// Set up Binding
        func setupBinding(){
            // Posts
//            viewModel.posts
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { posts in
//                    self.data = posts
//                    self.tableView.reloadData()
//                }).disposed(by: disposeBag)
//
//            viewModel.isLoading
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { isLoading in
//                    if isLoading {
//                        self.loadingAnimation.alpha = 1
//                        self.loadingAnimation.play()
//                    } else {
//                        self.loadingAnimation.alpha = 0
//                        self.loadingAnimation.stop()
//                    }
//                }).disposed(by: disposeBag)
//
//            viewModel.error
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { err in
//                    self.showAlert(err.localizedDescription)
//                }).disposed(by: disposeBag)
//
//            ProfileViewModel.shared.cleardCache
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { cleard in
//                    if cleard {
//                        //self.tableView.reloadData()
//                    }
//                }).disposed(by: disposeBag)
        }
        
        func setupObservers(){
            
        }

    }
}

// MARK: - Table View Extensions
extension AmongChat.Home.FeedViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: FeedListCell.self, for: indexPath)
//        cell.configure(post: data[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If the cell is the first cell in the tableview, the queuePlayer automatically starts.
        // If the cell will be displayed, pause the video until the drag on the scroll view is ended
        if let cell = cell as? FeedListCell{
            oldAndNewIndices.1 = indexPath.row
            currentIndex = indexPath.row
//            cell.pause()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Pause the video if the cell is ended displaying
        if let cell = cell as? FeedListCell {
//            cell.pause()
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        for indexPath in indexPaths {
//            print(indexPath.row)
//        }
    }
    
    
}

// MARK: - ScrollView Extension
extension AmongChat.Home.FeedViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let cell = self.tableView.cellForRow(at: IndexPath(row: self.currentIndex, section: 0)) as? FeedListCell
//        cell?.replay()
    }
    
}

