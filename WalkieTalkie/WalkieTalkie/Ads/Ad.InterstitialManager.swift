////
////  Ad.InterstitialManager.swift
////  Castbox
////
////  Created by mayue_work on 2019/6/26.
////  Copyright © 2019 Guru. All rights reserved.
////
//
//import Foundation
//import RxSwift
//import RxCocoa
//import SwiftyUserDefaults
////import MoPub
//
//struct Ad {
//    
//}
//
//extension Ad {
//    
//    class InterstitialManager: NSObject {
//        
//        static let shared = InterstitialManager()
//        
//        private let interstitial: MPInterstitialAdController
//        
//        override private init() {
//            interstitial = {
//                let unitId = "6c140af189f042c0b5d1188bd1d7f49b"
//                let ad = MPInterstitialAdController(forAdUnitId: unitId)
//                return ad!
//            }()
//            super.init()
//            interstitial.delegate = self
//        }
//                
//        func showAdIfReady(from: UIViewController) {
//            guard interstitial.ready else {
//                loadAd()
//                return
//            }
//            interstitial.show(from: from)
//        }
//        
//        func loadAd() {
//            guard shouldShow() else {
//                return
//            }
//            
//            interstitial.loadAd()
//        }
//        
//        private func shouldShow() -> Bool {
//            let isPremium: Bool = Settings.shared.isProValue.value
//            let flag: Bool = !isPremium
//            return flag
//        }
//        
//    }
//}
//
//extension Ad.InterstitialManager: MPInterstitialAdControllerDelegate {
//    
//    
//    func interstitialDidLoadAd(_ interstitial: MPInterstitialAdController!) {
//        NSLog("")
//    }
//    
//    func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!) {
//        NSLog("")
//    }
//    
//    func interstitialDidFail(toLoadAd interstitial: MPInterstitialAdController!, withError error: Error!) {
//        NSLog("")
//    }
//    
//    func interstitialWillAppear(_ interstitial: MPInterstitialAdController!) {
//        
//    }
//    
//    func interstitialDidAppear(_ interstitial: MPInterstitialAdController!) {
//    }
//    
//    func interstitialWillDisappear(_ interstitial: MPInterstitialAdController!) {
//    }
//    
//    func interstitialDidDisappear(_ interstitial: MPInterstitialAdController!) {
//        loadAd()
//    }
//    
//    func interstitialDidExpire(_ interstitial: MPInterstitialAdController!) {
//        loadAd()
//    }
//    
//    func interstitialDidReceiveTapEvent(_ interstitial: MPInterstitialAdController!) {
//    }
//
//}
