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
            IQKeyboardManager.shared.shouldResignOnTouchOutside = true
            IQKeyboardManager.shared.enableAutoToolbar = false
            
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
    
    func chooseImage() {
        // 设置相册和相机
        let pickerVC = UIImagePickerController()
        if  UIImagePickerController.isSourceTypeAvailable(.camera) ||
            UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            pickerVC.delegate = self
        }
        
        let gotoSettingAlert = { [weak self] in
            guard let `self` = self else { return }
            let alertVC = UIAlertController(title: "Cuddle would like to take a photo", message: "Please switch on camera permission", preferredStyle: .alert)
            let resetAction = UIAlertAction(title: "Go Settings", style: .default, handler: { (_) in
                if let url = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertVC.addAction(cancelAction)
            alertVC.addAction(resetAction)
            DispatchQueue.main.async {
                self.navigationController?.present(alertVC, animated: true)
            }
        }
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    guard let `self` = self else { return }
                    pickerVC.sourceType = .photoLibrary
                    self.navigationController?.present(pickerVC, animated: true)
                } else {
                    gotoSettingAlert()
                }
            }
        })
    }
}

extension Report.ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        defer { picker.dismiss(animated: true, completion: nil) }
        guard let image = info[.originalImage] as? UIImage,
            let imgPng = image.scale(to: CGSize(width: 400, height: 400)) else {
                return
        }
        footerView.append(image: imgPng)
    }
    
    func show(toast errorMsg: String? = nil) {
        guard let msg = errorMsg else {
            return
        }
        view.raft.autoShow(.text(msg))
    }
}

extension Report.ViewController {
    func report(with index: Int, note: String, images: [UIImage]) {
        guard let reason = dataSource.safe(index) else {
//            Toast.showToast(alertType: .warnning, message: R.string.localizable.reportSelectReasonToast())
            return
        }
        let remove = view.raft.show(.loading)
        viewModel.report(with: reason, note: note, images: images)
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
        
        footerView.selectImageHandler = { [weak self] in
            self?.chooseImage()
        }
        
        footerView.reportHandler = { [weak self] index, text, images in
            self?.report(with: index, note: text, images: images)
        }
    }
    
    func configureSubview() {
        view.backgroundColor = Theme.mainBgColor
        view.addSubview(navView)
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        footerView = ReportFooterView(frame: CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 364 + ReportFooterView.collectionItemWidth))
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
