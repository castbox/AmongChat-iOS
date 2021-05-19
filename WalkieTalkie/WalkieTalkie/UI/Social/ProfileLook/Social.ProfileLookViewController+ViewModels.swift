//
//  Social.ProfileLookViewController+ViewModels.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/2/3.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Social.ProfileLookViewController {
    
    class DecorationViewModel {
        
        private(set) var decoration: Entity.DecorationEntity
        private(set) var decorationType: Entity.DecorationCategory.DecorationType
        
        init(dataModel: Entity.DecorationEntity, decorationType: Entity.DecorationCategory.DecorationType) {
            self.decoration = dataModel
            self.decorationType = decorationType
            self.suit = decoration.decoList?.compactMap({
                guard let decorationType = Entity.DecorationCategory.DecorationType.init(rawValue: $0.decoType) else {
                    return nil
                }
                let decoVM = DecorationViewModel(dataModel: $0, decorationType: decorationType)
                decoVM.selected = true
                return decoVM
            }) ?? []
        }
        
        var thumbUrl: String? {
            switch decorationType {
            case .skin, .bg, .pet:
                return decoration.url
            case .hat:
                return decoration.listUrl
            case .suit:
                return nil
            }
        }
        
        var lookUrl: String? {
            return decoration.url
        }
        
        var locked: Bool {
            return decoration.lock ?? false
        }
        
        var iapProduct: IAP.Product? {
            
            guard let product = decoration.product?.products.safe(0),
                  let iapProduct = IAP.consumableProducts[product.productId] else {
                return nil
            }

            return iapProduct
            
        }
        
        var selected: Bool {
            
            set {
                decoration.selected = newValue
            }
            
            get {
                return decoration.selected ?? false
            }
        }
        
        var suit: [DecorationViewModel]
        
        func unlock() {
            decoration.lock = false
        }
        
    }
    
    class DecorationCategoryViewModel {
        
        private let dataModel: Entity.DecorationCategory
        private(set) var decorationType: Entity.DecorationCategory.DecorationType
        
        private(set) var decorations: [DecorationViewModel]
        
        init?(dataModel: Entity.DecorationCategory) {
            
            guard let decorationType = Entity.DecorationCategory.DecorationType.init(rawValue: dataModel.name) else {
                return nil
            }
            
            self.dataModel = dataModel
            self.decorationType = decorationType
            self.decorations = dataModel.list.map({ DecorationViewModel(dataModel: $0, decorationType: decorationType) })
        }
        
        var name: String {
            switch decorationType {
            case .suit:
                return R.string.localizable.amongChatProfileImage()
            case .skin:
                return R.string.localizable.amongChatProfileSkin()
            case .bg:
                return R.string.localizable.amongChatProfileBg()
            case .hat:
                return R.string.localizable.amongChatProfileHat()
            case .pet:
                return R.string.localizable.amongChatProfilePet()
            }
        }
        
    }
    
}
