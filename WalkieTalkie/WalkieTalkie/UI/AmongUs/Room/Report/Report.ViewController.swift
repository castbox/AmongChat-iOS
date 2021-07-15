//
//  ReportViewController.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/15.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import AVFoundation
import IQKeyboardManagerSwift

// MARK: - vc
extension Report {
    class ViewController: WalkieTalkie.ViewController {
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = viewModel.type.title
            return n
        }()
        
        private lazy var tableView: UITableView = {
            let table = UITableView(frame: .zero)
//            table.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 3)
//            table.separatorColor = UIColor.theme(.separatorLight)
            table.separatorStyle = .none
            table.rowHeight = 44.5
            table.delegate = self
//            table.register
            table.dataSource = self
            table.register(UINib(nibName: ReportCell.className, bundle: nil),
                           forCellReuseIdentifier: ReportCell.className)
            return table
        }()
        
        var dataSource = [Entity.Report.Reason]() {
            didSet {
                tableView.reloadData()
            }
        }
        
//        private let id: String
//        private let image: UIImage?
//        private let type: ReportType
        private let viewModel: ViewModel
        private var footerView: ReportFooterView!
        private var completionHandler: CallBack?
        
        static func showReport(on targetVC: UIViewController,
                               uid: String,
                               type: ReportType,
                               roomId: String,
                               operate: Report.ReportOperate? = nil,
                               completionHandler: CallBack?) {
            let viewModel = ViewModel(uid, type: type, roomId: roomId, operate: operate)
            let controller = Report.ViewController(viewModel: viewModel)
            controller.completionHandler = completionHandler
            targetVC.navigationController?.pushViewController(controller, animated: true)
        }
        
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            IQKeyboardManager.shared.enable = true
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            IQKeyboardManager.shared.enable = false
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        override func viewDidLoad() {
            super.viewDidLoad()
                        
            title = viewModel.type.title
//            navigationBackItemConfig(Theme.currentMode == .light)
            
            configureSubview()
            bindSubviewEvent()
            
        }
        
//        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//            super.touchesBegan(touches, with: event)
//            view.endEditing(true)
//        }
    }
}

extension Report.ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReportCell.className) as! ReportCell
        cell.set(dataSource.safe(indexPath.row), isSelected: footerView.selectedIndex == indexPath.row)
        return cell
    }
}

extension Report.ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        footerView.selectedIndex = indexPath.row
        tableView.reloadData()
    }
}

extension Report.ViewController {
    
    func chooseMedia(_ type: ReportFooterView.MediaType) {
        selectMedia(type)
            .subscribe(onSuccess: { [weak self] item in
                guard let image = item.image?.scaled(toWidth: 400) else {
                    return
                }
                if let videoUrl = item.url {
                    self?.footerView.append(thumbnail: image, video: videoUrl)
                } else {
                    self?.footerView.append(image: image)
                }
            }) { error in
                
            }
            .disposed(by: bag)
    }
    
    private func selectMedia(_ type: ReportFooterView.MediaType) -> Single<ImagePickerManager.Result> {
        let pickerType: ImagePickerManager.PickerType
        switch type {
        case .image:
//            config.library.mediaType = .photo
            pickerType = .defaultImage
        case .video:
//            config.library.mediaType = .video
            pickerType = .reportVideo
        }
        
        return Single<ImagePickerManager.Result>.create(subscribe: { (subscriber) -> Disposable in
            
            ImagePickerManager.shared.selectMedia(for: pickerType, sourceType: .photoLibrary) { result in
                guard let item = result,
                      let _ = item.image else {
                    subscriber(.error(MsgError.default))
                    return
                }
                subscriber(.success(item))
            }
            return Disposables.create()
        })
    }
}

extension Report.ViewController {
    func show(toast errorMsg: String? = nil) {
        guard let msg = errorMsg else {
            return
        }
        view.raft.autoShow(.text(msg))
    }

    func report(with index: Int, note: String, images: [UIImage], videos: [URL]) {
        guard let reason = dataSource.safe(index) else {
//            Toast.showToast(alertType: .warnning, message: R.string.localizable.reportSelectReasonToast())
            return
        }
        let remove = view.raft.show(.loading)
        viewModel.report(with: reason, note: note, images: images, videos: videos)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] result in
                    guard let `self` = self else { return }
                    remove()
                    if result {
                        self.show(toast: R.string.localizable.reportSuccess())
                        self.navigationController?.popViewController(animated: true) { [weak self] in
                            self?.completionHandler?()
                        }
                    } else {
                        self.show(toast: R.string.localizable.reportFailed())
                    }
                }, onError: { [weak self] error in
                    remove()
                    self?.show(toast: error.localizedDescription)
            })
            .disposed(by: bag)
    }
    
    func bindSubviewEvent() {
        viewModel.dataSourceObjecct
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] list in
                self?.dataSource = list
            })
            .disposed(by: bag)
        
        footerView.selectMediaHandler = { [weak self] mediaType in
            self?.chooseMedia(mediaType)
        }
        
        footerView.reportHandler = { [weak self] index, text, images, videos in
            self?.report(with: index, note: text, images: images, videos: videos)
        }
    }
    
    func configureSubview() {
        view.backgroundColor = Theme.mainBgColor
        view.addSubview(navView)
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        footerView = ReportFooterView(frame: CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 460 + ReportFooterView.collectionItemWidth * 2))
//        footerView.append(image: image)
        
        tableView.tableHeaderView = ReportTableHeader(frame: CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 56))
//        tableView.rx.backgroundColor.setTheme(by: .mainBgColor).disposed(by: bag)
        tableView.backgroundColor = .clear
        tableView.tableFooterView = footerView
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(navView.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
    }
}
