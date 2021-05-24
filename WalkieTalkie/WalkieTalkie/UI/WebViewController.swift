//
//  WebViewController.swift
//  Quotes
//
//  Created by 江嘉睿 on 2020/4/8.
//  Copyright © 2020 Guru Network Limited Inc. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import WebViewJavascriptBridge
//import CBAlert

let estimatedProgressKeyPath = "estimatedProgress"
let titleKeyPath = "title"

class WebViewController: WalkieTalkie.ViewController {
    enum ContentType {
        case normal
        case gameSkill(Entity.UserGameSkill)
    }
    
    private let configuration: WKWebViewConfiguration?
    var webView: WKWebView!
    
    private var progressView: UIProgressView?
    
    // 解决夜间模式下WKWebview-CompositingView还是显示白色的问题
//    fileprivate lazy var cover: UIView = {
//        let view = UIView(frame: self.view.bounds)
//        view.rx.backgroundColor.setTheme(by: .backgroundWhite).disposed(by: bag)
//        return view
//    }()
    
    var contentType: ContentType = .normal
    var url: URL? {
        didSet {
            isNavigationBarHiddenWhenAppear = hidesNavigationBar
        }
    }
    
    private var iapBridge: JSBridge?

    private var isShowProgressView: Bool {
        return navigationController?.navigationBar != nil
    }
    
    @discardableResult
    static func pushFrom(_ controller: UIViewController,
                         url: URL? = nil,
                         contentType: WebViewController.ContentType? = nil) -> WebViewController? {
        //contentType
        var nilableRequestUrl: URL?
//        if let contentType = contentType {
//            nilableRequestUrl = contentType.url
//            switch contentType {
//            case .helpdesk:
//                Logger.PageShow.logger("account", "help_clk", nil, nil)
//            default:
//                break
//            }
//        }
        if nilableRequestUrl == nil {
            nilableRequestUrl = url
        }
        
        guard let requestUrl = nilableRequestUrl else {
            return nil
        }
        
        guard !shouldOpenInSafari(requestUrl.absoluteString) else {
            UIApplication.shared.open(requestUrl, options: [:], completionHandler: nil)
            return nil
        }
        
        let webview = WebViewController()
        switch Settings.shared.theme.value {
        case .light:
            webview.statusBarStyle = .default
        case .dark:
            webview.statusBarStyle = .lightContent
        }
        webview.url = requestUrl
        webview.contentType = contentType ?? .normal
        controller.navigationController?.pushViewController(webview, animated: true)
        return webview
    }
    
    static func shouldOpenInSafari(_ urlString: String?) -> Bool {
        return false
//        guard let url = urlString,
//            FireStore.shared.isInReviewReplay.value else {
//                return false
//        }
//        let arrays = [
//            "cuddlelive.com/helpdesk",
//            "cuddlelive.com/cuddle-help-center",
//            "cuddlelive.com/help", ]
//        return arrays.contains(where: { url.contains($0, caseSensitive: false) })
    }
    
    var hidesNavigationBar: Bool {
       if let url = url, url.absoluteString.contains("hide_title=1") {
           return true
       } else {
           return false
       }
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: estimatedProgressKeyPath)
        webView?.removeObserver(self, forKeyPath: titleKeyPath)
        //        webView.scrollView.delegate = nil
    }
    
    init(configuration: WKWebViewConfiguration? = nil) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// https://github.com/lionheart/openradar-mirror/issues/18418
    /// https://stackoverflow.com/questions/37380333/modal-view-closes-when-selecting-an-image-in-wkwebview-ios
    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        if self.navigationController == nil || self.presentedViewController != nil {
            super.dismiss(animated: flag, completion: completion)
        } else {
            return
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSubview()
        bindSubviewEvent()
        
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case estimatedProgressKeyPath?:
            let estimatedProgress = webView.estimatedProgress
            progressView?.alpha = 1
            progressView?.setProgress(Float(estimatedProgress), animated: true)
            
            if estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                    self.progressView?.alpha = 0
                }, completion: { finished in
                    self.progressView?.setProgress(0, animated: true)
                })
            }
        case titleKeyPath?:
            if URL(string: navigationItem.title ?? "")?.appendingPathComponent("") == url?.appendingPathComponent("") {
                switch contentType {
                case .gameSkill(_):
                    ()
                default:
                    navigationItem.title = webView.title
                }
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func backButtonClick(button: UIButton) {
        if webView.canGoBack {
            webView.goBack()
        } else {
            super.backButtonClick(button: button)
        }
    }
    
    private func load(url: URL) {
        // WKWebView.reload 方法必须在页面加载成功的时候调用才会生效，当页面加载失败的时候，必须保存url重新load request
        // https://stackoverflow.com/questions/45706866/wkwebview-reload-cant-refresh-current-page
        self.url = url
        
        //        var request = URLRequest(url: url)
        var request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 60)
        request.timeoutInterval = 15.0
        request.setValue(APIService.Config.userAgent, forHTTPHeaderField: "User-Agent")
        
        if Config.officialUrlHosts.contains(where: { url.host?.contains($0) ?? false }) {
//            Network.headers().forEach { (arg) in
//                let (key, value) = arg
//                request.setValue(value, forHTTPHeaderField: key)
//            }
            iapBridge = JSBridge(webview: webView)
            iapBridge?.vc = self
            iapBridge?.bridge.setWebViewDelegate(self)
        }
                
        webView.load(request)
    }
    
    func remove() {
//        cover.removeFromSuperview()
    }
}

extension WebViewController: WKNavigationDelegate {
    // 页面开始加载时调用
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        cdPrint("web:vc: web:vc: start provisional navigation")
        updateProgressViewFrame()
        // 隐藏navi
        if let url = url, url.absoluteString.contains("hide_title=1") {
            navigationController?.isNavigationBarHidden = true
        }
    }
    // 当内容开始返回时调用
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        cdPrint("web:vc: did commit navigation")
        remove()
    }
    // 页面加载完成之后调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        cdPrint("web:vc: did finish navigation")
        remove()
    }
    
    // 接收到服务器跳转请求之后调用
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        cdPrint("web:vc: did receive server redirect")
    }
    // 在收到响应后，决定是否跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        cdPrint("web:vc: decide policy for navigation response")
        
        decisionHandler(.allow)
    }
    // 在发送请求之前，决定是否跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            if Routes.canHandle(url) {
                decisionHandler(.cancel)
                // 个人页面跳转 webview中跳转
                if url.absoluteString.contains("/user"),
                   let uid = Int(url.absoluteString.split(separator: "/").last ?? "0") ?? Settings.loginUserId {
                    let vc = Social.ProfileViewController(with: uid)
                    self.navigationController?.pushViewController(vc, animated: true)
                    return
                }
                if let vc = self.presentingViewController {
                    vc.dismiss(animated: true) {
                        Routes.handle(url)
                    }
                } else {
                    Routes.handle(url)
                }
                return
            } else if let schema = url.scheme,
                schema == "mailto" {
                decisionHandler(.cancel)
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            } else if let host = url.host,
                host == "apps.apple.com" {
                decisionHandler(.cancel)
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        
        if !(navigationAction.targetFrame?.isMainFrame == true) {
            webView.evaluateJavaScript("var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}", completionHandler: nil)
        }
        
        decisionHandler(.allow)
    }
    
    // 如果URL证书有问题，如：网站使用的不是受信任的证书颁发机构颁发的证书, 不显示页面
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trust = challenge.protectionSpace.serverTrust {
                credential = URLCredential(trust: trust)
                if credential != nil {
                    disposition = .useCredential
                } else {
                    disposition = .performDefaultHandling
                }
            } else {
                disposition = .cancelAuthenticationChallenge
            }
        } else {
            disposition = .cancelAuthenticationChallenge
        }
        
        completionHandler(disposition, credential)
    }
    
    // webview 白屏
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
    
    // 页面开始加载数据时 失败时调用 Invoked when an error occurs while starting to load data for
    // the main frame.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        cdPrint("web:vc: didFailProvisionalNavigation")

    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        cdPrint("web:vc: didFail navigation:")
//        view.insertSubview(cover, aboveSubview: webView)
//        indicatorRemove = view.ind.show(.noNetwork, removeOnAction: true, action: { [weak self] in
//            guard let url = self?.url else { return }
//            self?.load(url: url)
//        })
    }
    
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        webView.load(navigationAction.request)
        return nil
    }
}

extension WebViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

private extension WebViewController {
    
    @objc func editButtonAction() {
        switch contentType {
        case let .gameSkill(skill):
            Logger.Action.log(.profile_game_state_detail_edit_clk, categoryValue: skill.topicId)
            let game = Social.ChooseGame.GameViewModel(with: Entity.GameSkill(topicId: skill.topicId,
                                                                              topicName: skill.topicName,
                                                                              coverUrl: "",
                                                                              example: skill.example,
                                                                              isAdd: false, status: 2))
            let addStatsVC = Social.AddStatsViewController(game)
            navigationController?.pushViewController(addStatsVC, animated: true)
            addStatsVC.gameUpdatedHandler = { [weak self] in
                
                guard let url = self?.url else {
                    return
                }
                self?.load(url: url)
            }
        default:
            ()
        }
    }
    
    func showSystemNavigationBar() {
        isNavigationBarHiddenWhenAppear = false
        self.navigationController?.navigationBar.setColors(background: UIColor.theme(.backgroundBlack), text: .white)
        self.navigationController?.navigationBar.setTitleFont(R.font.nunitoExtraBold(size: 24) ?? .systemFont(ofSize: 24, weight: .medium), color: .white)
        self.customBackButton.setImage(R.image.ac_back(), for: .normal)
    }

    func updateProgressViewFrame() {
        guard let progressView = progressView else {
            return
        }
        progressView.frame = CGRect(x: 0, y: 0, width: webView.frame.size.width, height: 2)
        
        if progressView.superview == nil {
            progressView.tintColor = "88BB60".color()
            webView.addSubview(progressView)
            //            navigationController.navigationBar.addSubview(progressView)
        }
    }
    
    func bindSubviewEvent() {
        if let url = url {
            load(url: url)
        }
        webView.addObserver(self, forKeyPath: estimatedProgressKeyPath, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: titleKeyPath, options: .new, context: nil)
    }
    
    func configureSubview() {
        showSystemNavigationBar()
        
        webView = configuration.map({ WKWebView(frame: .zero, configuration: $0) }) ?? WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false /// 取消 3D touch 功能
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        
//        switch contentType {
//        case .helpdesk:
//            Logger.Screen.log(.help)
//        case .achievement:
//            webView.scrollView.alwaysBounceVertical = false
//        default:
//            break
//        }
        
        webView.rx.backgroundColor.setTheme(by: .backgroundBlack).disposed(by: bag)
        view.rx.backgroundColor.setTheme(by: .backgroundBlack).disposed(by: bag)
        
        view.addSubview(webView)
        automaticallyAdjustsScrollViewInsets = false
        webView.snp.makeConstraints { (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        webView.scrollView.rx.backgroundColor.setTheme(by: .backgroundBlack).disposed(by: bag)
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.trackTintColor = UIColor(white: 1, alpha: 0)
        self.progressView = progressView
        
        updateProgressViewFrame()
        
        switch contentType {
        case let .gameSkill(skill):
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.ac_icon_game_edit(), style: .done, target: self, action: #selector(editButtonAction))
            title = skill.topicName
        default:
            ()
        }

    }
}

