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

    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var skipButtonBottomConstraint: NSLayoutConstraint!
    private var isStartTimer: Bool = false
    private let thirdPage = R.storyboard.main.premiumViewController()!
    private var isFirstShowPage2 = false
    private var isFirstShowPage3 = false
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        thirdPage.view.frame = CGRect(x: Frame.Screen.width * 2, y: 0, width: Frame.Screen.width, height: Frame.Screen.height)
    }
    
    @IBAction func skipAction(_ sender: Any) {
//        dismiss(animated: true, completion: nil)
        self.dismissHandler?()
    }
    
    @IBAction func continueAction(_ sender: Any) {
        let index = pageIndex + 1
        if index > maxPage { //last page
            thirdPage.buySelectedProducts()
        } else {
            scrollView.setContentOffset(CGPoint(x: scrollView.width * index.cgFloat, y: 0), animated: true)
        }
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
        
        if pageIndex == 1, !isFirstShowPage2 {
            isFirstShowPage2 = true
            Logger.PageShow.log(.tutorial_imp_2)
        }
        pageControl.currentPage = pageIndex
    }
}

extension GuideViewController {
    func updateContinueButtonTitle() {
        guard pageIndex == 2 else {
            return
        }
        pageControl.isHidden = true
        startShowSkipButtonTimer()
        
        let tryAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 14, weight: .bold)
        ]
        
        let mutableNormalString = NSMutableAttributedString()
        if selectedProductId == IAP.productYear {
            if FireStore.shared.isInReviewSubject.value {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideSubscribeTitle(), attributes: tryAttr))
            } else {
                let tryDesAttr: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.black.alpha(0.7),
                    .font: UIFont.systemFont(ofSize: 12)
                ]
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.premiumTryTitle(), attributes: tryAttr))
                mutableNormalString.append(NSAttributedString(string: "\n\(R.string.localizable.premiumTryTitleDes())", attributes: tryDesAttr))
            }
        } else {
            mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideContinue(), attributes: tryAttr))

        }
        UIView.setAnimationsEnabled(false)
        continueButton.setAttributedTitle(mutableNormalString, for: .normal)
        continueButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        
        if !isFirstShowPage3 {
            isFirstShowPage3 = true
            Logger.IAP.logImp(.first_open)
        }
        
    }
    
    func updateSubviewStatus(_ pageIndex: Int) {
        if pageIndex == 2 {
//            continueButton.isHidden = true
            pageControl.isHidden = true
            scrollView.isScrollEnabled = false
            startShowSkipButtonTimer()
        }
    }
    
    func startShowSkipButtonTimer() {
        guard !isStartTimer else {
            return
        }
        isStartTimer = true
        Observable.just(())
            .delay(.seconds(3), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.skipButtonBottomConstraint.constant = 0
                UIView.animate(withDuration: AnimationDuration.normal.rawValue) {
                    self?.view.layoutIfNeeded()                
                }
            })
            .disposed(by: bag)
    }
    
    func bindSubviewEvent() {
        
    }
    
    func configureSubview() {
        let firstPage = GuideFirstView(frame: Frame.Screen.bounds)
        scrollView.addSubview(firstPage)
        
        let secondPage = GuideSecondView(frame: Frame.Screen.bounds)
        secondPage.x = Frame.Screen.width
        scrollView.addSubview(secondPage)
        
        thirdPage.style = .guide
        thirdPage.source = .first_open
        thirdPage.dismissHandler = { [weak self] in
//            self?.dismiss(animated: true, completion: nil)
            self?.dismissHandler?()
        }
        thirdPage.didSelectProducts = { [weak self] pid in
            self?.selectedProductId = pid
        }
        thirdPage.view.frame = CGRect(x: Frame.Screen.width * 2, y: 0, width: Frame.Screen.width, height: Frame.Screen.height)
//        thirdPage.willMove(toParent: self)
        addChild(thirdPage)
        scrollView.addSubview(thirdPage.view)
        
        scrollView.contentSize = CGSize(width: Frame.Screen.width * 3, height: Frame.Screen.height)
        
        continueButton.titleLabel?.lineBreakMode = .byWordWrapping
        continueButton.titleLabel?.textAlignment = .center
    }
}

