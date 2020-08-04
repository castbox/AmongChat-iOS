//
//  GuideViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import RxSwift
import RxCocoa

class GuideViewController: ViewController {
    
    @IBOutlet weak var continueButton: WalkieButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var continueButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var iapTipsLabel: UILabel!
    
    private var isStartTimer: Bool = false
    private let fourthPage = R.storyboard.main.premiumViewController()!
    private var isFirstShowPage2 = false
    private var isFirstShowPage3 = false
    private var isFirstShowPage4 = false
    private var iapTipsLabelText = R.string.localizable.premiumTryTitleDes("$29.99")
    private var productMaps: [String: IAP.Product] = [:]
    private var selectedProductId: String? {
        didSet {
            updateContinueButtonTitle()
        }
    }
    var dismissHandler: (()->Void)? = nil
    
    var maxPage: Int {
        Int(scrollView.contentSize.width / scrollView.width) - 1
    }
    var pageIndex: Int {
        Int(scrollView.contentOffset.x / scrollView.width)
    }
    
    override var screenName: Logger.Screen.Node.Start {
        return .tutorial
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Defaults[\.firstInstall] = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
        Logger.PageShow.log(.tutorial_imp_1)
        mainQueueDispatchAsync(after: 0.2) {
            self.showEndUserLicenseAgreement()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fourthPage.view.frame = CGRect(x: Frame.Screen.width * 3, y: 0, width: Frame.Screen.width, height: Frame.Screen.height)
    }
    
    @IBAction func skipAction(_ sender: Any) {
        //        dismiss(animated: true, completion: nil)
        self.dismissHandler?()
    }
    
    @IBAction func continueAction(_ sender: Any) {
        let index = pageIndex + 1
        if index > maxPage { //last page
            fourthPage.buySelectedProducts()
        } else {
            scrollView.setContentOffset(CGPoint(x: scrollView.width * index.cgFloat, y: 0), animated: true)
        }
    }
    @IBAction func privacyAction(_ sender: Any) {
        open(urlSting: "https://walkietalkie.live/policy.html")
    }
}

extension GuideViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var pageIndex = Int(scrollView.contentOffset.x / scrollView.width)
        if pageIndex < 0 {
            pageIndex = 0
        } else if pageIndex > maxPage {
            pageIndex = maxPage
        }
        updateSubviewStatus(pageIndex)
        updateContinueButtonTitle()
        privacyButton.isHidden = pageIndex > 0
        if pageIndex == 1, !isFirstShowPage2 {
            isFirstShowPage2 = true
            Logger.PageShow.log(.tutorial_imp_2)
        } else if pageIndex == 2, !isFirstShowPage3 {
            isFirstShowPage3 = true
            Logger.PageShow.log(.tutorial_imp_3)
        }
    }
}

extension GuideViewController {
    func updateContinueButtonTitle() {
        guard pageIndex == 3 else {
            iapTipsLabel.isHidden = true
            iapTipsLabel.fadeOut()
            return
        }
        let tryAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: R.font.nunitoBold(size: 18) ?? Font.bigBody.value,
            .kern: 0.5
        ]
        
        let mutableNormalString = NSMutableAttributedString()
        if Constants.abGroup == .b {
            if FireStore.shared.isInReviewSubject.value {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideSubscribeTitle(), attributes: tryAttr))
            } else {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.premiumFree3dTrial(), attributes: tryAttr))
            }
            iapTipsLabel.fadeIn()
            iapTipsLabel.isHidden = false
            
            if let pid = selectedProductId,
                pid == IAP.productYear,
                let product = productMaps[pid]?.skProduct {
                iapTipsLabel.text = """
                3-day free trial. Then \(product.localizedPrice) / Year.
                Recurring bilking.Cancel any time.
                """
            }
//            else if let pid = selectedProductId,
//                pid == IAP.productWeek,
//                let product = productMaps[pid]?.skProduct {
//                iapTipsLabel.text = """
//                \(product.localizedPrice) / Week.
//                Recurring bilking.Cancel any time.
//                """
//            } else if let pid = selectedProductId,
//                pid == IAP.productMonth,
//                let product = productMaps[pid]?.skProduct {
//                iapTipsLabel.text = """
//                \(product.localizedPrice) / Month.
//                Recurring bilking.Cancel any time.
//                """
//            }
        } else {
            if selectedProductId == IAP.productYear {
                if FireStore.shared.isInReviewSubject.value {
                    mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideSubscribeTitle(), attributes: tryAttr))
                } else {
                    mutableNormalString.append(NSAttributedString(string: R.string.localizable.premiumTryTitle(), attributes: tryAttr))
                }
            } else {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideContinue(), attributes: tryAttr))
                
            }
        }
        UIView.setAnimationsEnabled(false)
        continueButton.setAttributedTitle(mutableNormalString, for: .normal)
        continueButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        
        if !isFirstShowPage4 {
            isFirstShowPage4 = true
            Logger.IAP.logImp(.first_open)
        }
        
    }
    
    func updateSubviewStatus(_ pageIndex: Int) {
        if pageIndex == 3 {
            //            continueButton.isHidden = true
            scrollView.isScrollEnabled = false
        }
    }
    
    func showEndUserLicenseAgreement() {
        let vc = EndUserLicenseController()
        vc.showModal(in: self)
//        let alertVC = UIAlertController(
//            title: R.string.localizable.endUserLicenseTitle(),
//            message: R.string.localizable.endUserLicenseContent(),
//            preferredStyle: UIAlertController.Style.alert)
//        let confirmAction = UIAlertAction(title: R.string.localizable.iKnow(), style: .default, handler: { _ in
//
//        })
//
//        let newWidth = UIScreen.main.bounds.width - 50
//        let height = NSLayoutConstraint(item: alertVC.view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.view.frame.height * 0.60)
//        let width = NSLayoutConstraint(item: alertVC.view, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: newWidth)
//
//        alertVC.view.addConstraint(height)
//        alertVC.view.addConstraint(width)

//        let newHeight = UIScreen.main.bounds.height - 220
//
//        // update width constraint value for main view
//        if let viewWidthConstraint = alertVC.view.constraints.filter({ return $0.firstAttribute == .width }).first {
//            viewWidthConstraint.constant = newWidth
//        }
//
//        // update width constraint value for container view
//        if let containerViewWidthConstraint = alertVC.view.subviews.first?.constraints.filter({ return $0.firstAttribute == .width }).first {
//            containerViewWidthConstraint.constant = newWidth
//        }
//
//        // update width constraint value for main view
//        if let viewHeightConstraint = alertVC.view.constraints.filter({ return $0.firstAttribute == .height }).first {
//            viewHeightConstraint.constant = newHeight
//        }
//
//        // update width constraint value for container view
//        if let containerViewHeightConstraint = alertVC.view.subviews.first?.constraints.filter({ return $0.firstAttribute == .height }).first {
//            containerViewHeightConstraint.constant = newHeight
//        }

//        alertVC.addAction(confirmAction)
//        present(alertVC, animated: true, completion: nil)

    }
    
    func bindSubviewEvent() {

        FireStore.shared.onlineChannelList()
//            .debug()
            .map { items -> Room? in
                let sortedItems = items.sorted {
                    $0.user_count > $1.user_count
                }
                return sortedItems.first(where: { $0.user_count <= 4 })
            }
//            .debug()
            .filterNil()
            .subscribe(onNext: { room in
                Defaults.set(channel: room, mode: .public)
            })
            .disposed(by: bag)
        
        IAP.productsValue
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] maps in
                self?.productMaps = maps
            })
            .disposed(by: bag)

    }
    
    func configureSubview() {
        if Constants.abGroup == .a {
            if Frame.Height.deviceDiagonalIsMinThan4_7 {
                continueButtonHeightConstraint.constant = 44
                continueButtonBottomConstraint.constant = 25
                continueButton.cornerRadius = 22
            } else if Frame.Height.deviceDiagonalIsMinThan5_5 {
                continueButtonBottomConstraint.constant = Frame.Scale.height(50)
            }
        }
        
        continueButton.appendKern()
        
        let firstPage = GuideFirstView(frame: Frame.Screen.bounds)
        scrollView.addSubview(firstPage)
        
        let secondPage = GuideSecondView(frame: Frame.Screen.bounds)
        secondPage.x = Frame.Screen.width
        scrollView.addSubview(secondPage)
        
        let thirdPage = GuideThirdView(frame: Frame.Screen.bounds)
        thirdPage.x = Frame.Screen.width * 2
        scrollView.addSubview(thirdPage)
        
        fourthPage.style = .guide
        fourthPage.source = .first_open
        fourthPage.dismissHandler = { [weak self] in
            //            self?.dismiss(animated: true, completion: nil)
            self?.dismissHandler?()
        }
        fourthPage.didSelectProducts = { [weak self] pid in
            self?.selectedProductId = pid
        }
        fourthPage.view.frame = CGRect(x: Frame.Screen.width * 3, y: 0, width: Frame.Screen.width, height: Frame.Screen.height)
        //        fourthPage.willMove(toParent: self)
        addChild(fourthPage)
        scrollView.addSubview(fourthPage.view)
        
        scrollView.contentSize = CGSize(width: Frame.Screen.width * 4, height: Frame.Screen.height)
        
        continueButton.titleLabel?.lineBreakMode = .byWordWrapping
        continueButton.titleLabel?.textAlignment = .center
    }
}

