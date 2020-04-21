//
//  UIViewController+Safari.swift
//  HUFUWallet
//
//  Created by Wilson on 2018/5/21.
//  Copyright © 2018 Hufu inc. All rights reserved.
//

import Foundation
import SafariServices

extension UIViewController {
    func open(urlSting: String) {
        guard let url = URL(string: urlSting) else {
            return
        }
        self.open(url: url)
    }
    
    func open(url: URL) {
        var variableUrl = url
        if url.scheme == nil {
            let urlString = url.absoluteString
            var urlComponent = URLComponents(string: urlString)
            urlComponent!.scheme = "http"
            variableUrl = urlComponent!.url!
        }
        let safari: SFSafariViewController
        if #available(iOS 11.0, *) {
            let configuration = SFSafariViewController.Configuration()
            configuration.entersReaderIfAvailable = false
            safari = SFSafariViewController(url: variableUrl, configuration: configuration)
        } else {
            // Fallback on earlier versions
            safari = SFSafariViewController(url: variableUrl, entersReaderIfAvailable: false)
        }
        
        present(safari, animated: true) {
        }
    }
}

extension UIViewController: SFSafariViewControllerDelegate {
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
    }
}
