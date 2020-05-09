//
//  WebViewController.swift
//  Quotes
//
//  Created by 江嘉睿 on 2020/4/8.
//  Copyright © 2020 Guru Network Limited Inc. All rights reserved.
//

import WebKit
import SnapKit

class WebController: ViewController {
    
    let webView = WKWebView()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func setLeftButtonDone() {
        self.navigationItem.leftBarButtonItem = .init(title: "Done", style: .done, target: self, action: #selector(dismissWithNavigationContainer))
    }
    
    @objc private func dismissWithNavigationContainer() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
        view.addSubview(webView)
        view.backgroundColor = .black
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    var headers: [String : String]? {
        var ua: [String: String] = [:]
//        if let d = Request.device() {
//            ua["deviceId"] = d.id
//            ua["timeZone"] = d.timeZone
//            ua["language"] = d.language
//        }
//        if let a = Request.app() {
//            ua["appIdentifier"] = a.identifier
//            ua["appVersion"] = a.version
//        }
//        let uaString = ua.map({"\($0)=\($1)"}).joined(separator: ";") + ";"
        let uaString = ""
        return ["Content-type": "application/json", "X-Quotes-UA": uaString]
    }
    
    var scannerUa: String {
        var ua: [String: String] = [:]
//        if let d = Request.device() {
//            ua["deviceId"] = d.id
//            ua["lang"] = d.language
//            ua["timeZone"] = d.timeZone
//            ua["deviceType"] = "iOS"
//        }
//        if let a = Request.app() {
//            ua["appIdentifier"] = a.identifier
//            ua["appVersion"] = a.version
//        }
//        let uaString = ua.map({"\($0)=\($1)"}).joined(separator: ";") + ";"
        let uaString = ""
        return uaString
    }
    
    func setHtml(text: String) {
        webView.loadHTMLString(text, baseURL: nil)
    }
    
    func setUrlPath(path: String) {
        if let url = URL(string: path) {
            var request = URLRequest(url: url)
            request.setValue(scannerUa, forHTTPHeaderField: "X-Quotes-UA")
            webView.load(request)
        }
    }
}

extension WebController: WKNavigationDelegate {
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
}

extension WebController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        webView.load(navigationAction.request)
        return nil
    }
}
