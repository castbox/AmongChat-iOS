//
//  PhotoManager.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/27.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit
import Photos

class PhotoManager: NSObject {
    static let albumName = "WalkieTalkie"
    static let shared = PhotoManager()

    var assetCollection: PHAssetCollection?

    override init() {
        super.init()

        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
    }

    func requestAuthorization(_ completionHandler: ((PHAuthorizationStatus) -> Void)?) {
        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) -> Void in
            completionHandler?(status)
        }
//        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
//            // ideally this ensures the creation of the photo album even if authorization wasn't prompted till after init was done
//            print("trying again to create the album")
////            self.createAlbum()
//        } else {
//            print("should really prompt the user to let them know it's failed")
//        }
    }

    func createAlbum(_ completionHandler: ((Error?) -> Void)?) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: PhotoManager.albumName)   // create an asset collection with the album name
        }) { success, error in
            if success {
                self.assetCollection = self.fetchAssetCollectionForAlbum()
                completionHandler?(nil)
            } else {
                print("error \(String(describing: error))")
                completionHandler?(error)
            }
        }
    }

    func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", PhotoManager.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }

    func save(_ image: UIImage, completion: @escaping ((String?, Error?) -> ())) {
        let saveHandler = { [unowned self] in
            guard let assetCollection = self.assetCollection else {
                return
            }
            var assetPlaceHolder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                let enumeration: NSArray = [assetPlaceHolder!]
                albumChangeRequest!.addAssets(enumeration)
            }, completionHandler: { result, error in
                guard let identifier = assetPlaceHolder?.localIdentifier else {
                    completion(nil, error)
                    return
                }
//                let assetIdentifier = identifier.replacingOccurrences(of: "/.*", with: "")
//                let urlString = "assets-library://asset/asset.png?id=\(assetIdentifier)&ext=png"
                completion(identifier, error)
            })
        }
        if assetCollection != nil {
            saveHandler()
        } else {
            createAlbum { error in
                if error == nil {
                    saveHandler()
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
    
//    func save(_ image: UIImage, completion: @escaping ((String?, Error?) -> ())) {
//        let saveHandler = { [unowned self] in
//            guard let assetCollection = self.assetCollection else {
//                return
//            }
//            var assetPlaceHolder: PHObjectPlaceholder?
//            PHPhotoLibrary.shared().performChanges({
//                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
//                assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
//                let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
//                let enumeration: NSArray = [assetPlaceHolder!]
//                albumChangeRequest!.addAssets(enumeration)
//            }, completionHandler: { result, error in
//                guard let identifier = assetPlaceHolder?.localIdentifier else {
//                    completion(nil, error)
//                    return
//                }
//                let assetIdentifier = identifier.replacingOccurrences(of: "/.*", with: "")
//                let urlString = "assets-library://asset/asset.png?id=\(assetIdentifier)&ext=png"
//                completion(urlString, error)
//            })
//        }
//        if let assetCollection = assetCollection {
//            saveHandler()
//        } else {
//            createAlbum { [weak self] error in
//                if error == nil {
//                    saveHandler()
//                } else {
//                    completion(nil, nil)
//                }
//            }
//        }
//    }
}
