//
//  JSBridge.swift
//  Castbox
//
//  Created by ChenDong on 2018/6/13.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
//import CastboxNetwork
import WebViewJavascriptBridge
import SwifterSwift
import Adjust
/// JSBridge Protocol: https://note.youdao.com/share/?id=6a9bfbcfc68b6d21a41296d4bb9d845b&type=note#/
/// Premium Content Wondery: https://docs.google.com/document/d/1Eu4IjntOguRvzRRxfkXjReRV5zzt0WSxyq9ssc2EnyY/edit#heading=h.82n7wupa0xzj

class JSBridge {
    enum ContentType: String {
        case web
    }
    
    let bridge: WebViewJavascriptBridge
    weak var vc: UIViewController?
    weak var owner: UIView?
    
    init(webview: WKWebView, type: ContentType = .web) {
        bridge = WebViewJavascriptBridge(forWebView: webview)
        
        weak var welf = self
        // game ready
        bridge.registerHandler("getUserData") { (data, callback) in
            let res = Response()
            
            if let dict = Settings.shared.loginResult.value?.dictionary {
                for(key, val) in dict {
                    _ = res.set(value: val, for: key)
                }
            }
            
            callback?(res.json)
        }
    
//        bridge.registerHandler("getProductInfoById") { (data, callback) in
//            guard let request = Request(data), let pid = request.value["id"] as? String else { return }
//            IAP.ProductFetcher.fetchProducts(of: [pid], completion: { (error, products) in
//                guard let p = products[pid] else { return }
//                guard let content = IAP.Product.parse(pid)?.category else { return }
//
//                var res = Response()
//                    .set(value: pid, for: "id")
//                    .set(value: p.skProduct.localizedPrice, for: "price")
//
//                switch content {
//                case let .sub(free: trial, renewal: renewal):
//                    res = res.set(value: renewal.asPerDuration(), for: "renewal")
//                    if let trial = trial {
//                        res = res.set(value: trial.asDuration(), for: "trial")
//                    }
//                case .iap:
//                    break
//                }
//                callback?(res.json)
//            })
//        }
//        bridge.registerHandler("productBuyById") { (data, callback) in
//            guard let request = Request(data),
//                  let pid = request.value["id"] as? String else { return }
//
//            guard Login.canDoLoginEvent() else {
//                return
//            }
//
//            IAP.ProductFetcher.fetchProducts(of: [pid], completion: { (error, products) in
//                guard let product = products[pid] else { return }
//
//                IAP.ProductDealer.pay(product, onState: { (state, transaction, error) in
//                    switch state {
//                    case .purchased, .restored:
//                        Knife.IAP.shared.uploadReceipt { error in
//                            if let error = error {
//                                let res = Response()
//                                    .set(code: 1)
//                                    .set(msg: error.localizedDescription)
//                                callback?(res.json)
//                            } else {
//                                let res = Response()
//                                    .set(msg: NSLocalizedString("PURCHASED", comment: ""))
//                                    .set(value: pid, for: "id")
//                                    .set(value: true, for: "success")
//                                callback?(res.json)
//
//                                if product.skProduct.dollarPrice != "Unknown" {
//                                    let adjustEvent = ADJEvent(eventToken: Analytics.Adjust.EventName.recharge_success.rawValue)
//
//                                    let priceCoin = product.skProduct.dollarPrice.double() ?? 0
//                                    let price: String = String(format: "%0.2f", priceCoin / 100.0)
//                                    adjustEvent?.setRevenue(Double(price) ?? 0, currency: "USD")
//                                    adjustEvent?.setTransactionId(transaction?.transactionIdentifier ?? "")
//                                    Adjust.trackEvent(adjustEvent)
//                                }
//                            }
//                        }
//                    case .failed:
//                        let res = Response()
//                            .set(code: 1)
//                            .set(msg: NSLocalizedString("Loading failed. Retry?", comment: ""))
//                        callback?(res.json)
//                    default:
//                        break
//                    }
//                })
//            })
//        }
        
        bridge.registerHandler("closeWebview") { (data, callback) in
            /// 关闭页面
            guard let `self` = welf else { return }
            if let vc = self.vc?.presentingViewController {
                vc.dismiss(animated: true, completion: nil)
            } else if let nv = self.vc?.navigationController {
                nv.popViewController(animated: true)
            }
        }
        
        // 分享
//        bridge.registerHandler("share") { (data, callback) in
//            guard let `self` = welf else { return }
//            guard let request = Request(data), let title = request.value["title"] as? String, let url = request.value["url"] as? String else { return }
//            self.vc?.share(title: title, url: url, image: nil, content: .web)
//        }
//
//        // 分享到facebook
//        bridge.registerHandler("shareWithFb") { (data, callback) in
//            guard let `self` = welf else { return }
//            guard let request = Request(data), let title = request.value["title"] as? String, let URLString = request.value["url"] as? String, let url = URL(string: URLString) else { return }
//            let shareInfo = ShareInfo(url: url, title: title, image: nil, content: nil)
//            Share.Facebook().share(with: shareInfo, at: self.vc)
//        }
//
//        // 分享到twitter
//        bridge.registerHandler("shareWithTwitter") { (data, callback) in
//            guard let `self` = welf else { return }
//            guard let request = Request(data), let title = request.value["title"] as? String, let URLString = request.value["url"] as? String, let url = URL(string: URLString) else { return }
//            let shareInfo = ShareInfo(url: url, title: title, image: nil, content: nil)
//            Share.Twitter().share(with: shareInfo, at: self.vc)
//        }
//
//        // 分享到whatsapp
//        bridge.registerHandler("shareWithWhatsapp") { (data, callback) in
//            guard let `self` = welf else { return }
//            guard let request = Request(data), let title = request.value["title"] as? String, let URLString = request.value["url"] as? String, let url = URL(string: URLString) else { return }
//            let shareInfo = ShareInfo(url: url, title: title, image: nil, content: nil)
//            Share.Whats().share(with: shareInfo, at: self.vc)
//        }
//
//        // 获取当天收听数据，需经过加密
//        bridge.registerHandler("getToDayListenInfo") { (data, callback) in
//            let res = Response()
//                .set(value: "\(JSBridge.Support.shared.elapsedTime)".entryptionValue(), for: "play_duration")
//            callback?(res.json)
//        }
//
        
        //eventLogger: 调用 native Firebase Analytics api
        bridge.registerHandler("eventLogger") { (data, callback) in
            guard let request = Request(data) else {
                return
            }
            cdPrint("[eventLogger]: \(String(describing: Date().toMillis())) \(data)")
            GuruAnalytics.log(event: request.value["event_name"] as? String ?? "",
                          category: request.value["category"] as? String,
                          name: request.value["item_name"] as? String,
                          value: request.value["value"] as? Int64)
        }
        
        //login: 调用 native 登陆半页窗口
        bridge.registerHandler("login") { [unowned webview] (data, callback) in
            AmongChat.Login.doLogedInEvent(style: .inAppLogin) { [weak webview] in
                webview?.reload()
            }
        }
        
//        bridge.registerHandler("refreshFinanceInfo") { [unowned webview] (data, callback) in
//            guard Login.canDoLoginEvent() else {
//                return
//            }
//            Knife.Settings.shared.refreshFinanceInfo()
//        }
        
        //setStatusBarBgColor: 修改状态栏背景色
        bridge.registerHandler("setStatusBarBgColor") { [unowned self] (data, callback) in
            guard let request = Request(data) else {
                return
            }
            
            if let rgba = (request.value["bg_color"] as! String).argb2rgba {
                self.vc?.view.backgroundColor = UIColor(rgba)
            } else {
                // toplist color
                if (request.value["bg_color"] as! String).count == 7 {
                    let rgba = UIColor(request.value["bg_color"] as! String)
                    self.vc?.view.backgroundColor = rgba
                }
            }
            
            if let _ = self.vc {
                webview.snp.remakeConstraints({ (make) in
                    make.left.right.bottom.equalToSuperview()
                    if let btm = self.vc?.topLayoutGuide.snp.bottom {
                        make.top.equalTo(btm)
                    } else {
                        make.top.equalToSuperview()
                    }
                })
            }
            
            if let webVC = self.vc as? WebViewController {
                let fontBW = request.value["font_color"] as! Int8
                if fontBW == 1 {
                    //black
                    webVC.statusBarStyle = .default
                } else {
                    //white
                    webVC.statusBarStyle = .lightContent
                }
                self.vc?.setNeedsStatusBarAppearanceUpdate()
            }
            
            let res = Response()
                .set(code: 0)
                .set(msg: "ok")
            callback?(res.json)
        }
        
    }
    
    func updateVolume(value: Int) {
        bridge.callHandler("gameVoiceControl", data: value.string)
    }
}

extension JSBridge {
    
    class Request {
        
        let value: [String: Any]
        
        init?(_ data: Any?) {
            guard let data = data, let str = data as? String, let dt = str.data(using: .utf8) else { return nil }
            guard let dic = try? JSONSerialization.jsonObject(with: dt), let value = dic as? [String: Any] else { return nil }
            self.value = value
        }
    }
    
    class Response {
        
        var msg: String = "ok"
        var code = 0
        
        private(set) var data: [String: Any] = [:]
        
        func set(value: Any?, for key: String) -> Response {
            data[key] = value
            return self
        }
        
        func set(data: [String: Any]) -> Response {
            self.data = data
            return self
        }
        
        func set(msg: String) -> Response {
            self.msg = msg
            return self
        }
        
        func set(code: Int) -> Response {
            self.code = code
            return self
        }
        
        var json: String? {
            var dic: [String: Any] = [:]
            dic["code"] = code
            dic["msg"] = msg
            dic["data"] = data
            guard let dt = try? JSONSerialization.data(withJSONObject: dic),
                  let jsonString = String(data: dt, encoding: .utf8) else {
                cdAssertFailure("can not create json string")
                return nil
            }
            return jsonString
        }
    }
}

extension Date {
    
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    
    init(millis: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(millis / 1000))
        self.addTimeInterval(TimeInterval(Double(millis % 1000) / 1000 ))
    }
    
}
