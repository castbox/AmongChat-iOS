//
//  ImagePickerManager.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/7/27.
//  Copyright © 2020 Guru. All rights reserved.
//

import AVFoundation
import RxSwift
import RxCocoa
import Photos

class ImagePickerManager: NSObject {
    enum PickerType {
        case defaultImage
        case squareImage
        case reportVideo
        case stories
    }
    
    struct Result {
        let image: UIImage?
        //only video have this url
        let url: URL?
    }
    
    static let shared = ImagePickerManager()
    private var pickerType: PickerType = .defaultImage
    private var completionBlock: ((Result?) -> Void)?
    
    func selectMediasWithPathObserver(for type: PickerType) -> Observable<Result?> {
        return Observable.create { observer -> Disposable in
            self.select(for: type) { path in
                observer.onNext(path)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    func selectMedia(for type: PickerType, sourceType: UIImagePickerController.SourceType = .photoLibrary, completionBlock: ((Result?) -> Void)?) {
        checkPermission(for: sourceType) {
            self.select(for: type, sourceType: sourceType, completionBlock: completionBlock)
        }
    }
    
    private func select(for type: PickerType, sourceType: UIImagePickerController.SourceType = .photoLibrary, completionBlock: ((Result?) -> Void)?) {
        
        // 设置相册和相机
        let pickerVC = UIImagePickerController()
        pickerVC.delegate = self
        pickerVC.sourceType = sourceType
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) ||
            UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            switch type {
            case .stories:
                pickerVC.mediaTypes = ["public.movie"]
                pickerVC.videoMaximumDuration = 15
                if #available(iOS 11.0, *) {
                    pickerVC.videoExportPreset = AVAssetExportPreset1280x720
                } else {
                    // Fallback on earlier versions
                }
            case .reportVideo:
                pickerVC.mediaTypes = ["public.movie"]
                pickerVC.videoMaximumDuration = 60
                if #available(iOS 11.0, *) {
                    pickerVC.videoExportPreset = AVAssetExportPreset1280x720
                } else {
                    // Fallback on earlier versions
                }
            default:
                pickerVC.mediaTypes = ["public.image"]
                pickerVC.allowsEditing = type.allowsEditing
            }
        }
        pickerType = type
        self.completionBlock = completionBlock
        UIApplication.topViewController()?.present(pickerVC, animated: true)
    }
    
    func checkPermission(for type: UIImagePickerController.SourceType = .photoLibrary, completionHandler: CallBack?) {
        let gotoSettingAlert: (String) -> Void = { text in
            let alertVC = UIAlertController(title: R.string.localizable.ypImagePickerPermissionDeniedPopupTitle(), message: text, preferredStyle: .alert)
            let resetAction = UIAlertAction(title: R.string.localizable.ypImagePickerPermissionDeniedPopupGrantPermission(), style: .default, handler: { (_) in
                if let url = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
            let cancelAction = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel, handler: nil)
            alertVC.addAction(cancelAction)
            alertVC.addAction(resetAction)
            UIApplication.topViewController()?.present(alertVC, animated: true)
        }
        
        switch type {
        case .camera: //.reportVideo
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (success) in
                DispatchQueue.main.async {
                    if success {
                        completionHandler?()
                    } else {
//                        completionBlock?(nil)
                        gotoSettingAlert(R.string.infoplist.nsCameraUsageDescription())
                    }
                }
            })
        default:
            PHPhotoLibrary.requestAuthorization { status in
                mainQueueDispatchAsync {
                    switch status {
                    case .authorized, .limited:
                        completionHandler?()
                    case .denied, .notDetermined, .restricted:
                        gotoSettingAlert(R.string.infoplist.nsPhotoLibraryUsageDescription())
                    @unknown default:
                        ()
                    }
                }
            }
        }
    }
    
}

extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        completionBlock?(nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        defer { picker.dismiss(animated: true, completion: nil) }
        
        let viewController = UIApplication.navigationController
        
        switch pickerType {
        case .stories, .reportVideo:
            guard let videoURL = info[.mediaURL] as? URL else {
                completionBlock?(nil)
                return
            }
            // get video image
            let avAsset = AVURLAsset(url: videoURL, options: nil)
            let imageGenerator = AVAssetImageGenerator(asset: avAsset)
            imageGenerator.appliesPreferredTrackTransform = true
            var thumbnail: UIImage?
            do {
                thumbnail = try UIImage(cgImage: imageGenerator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 1), actualTime: nil))
            } catch let e as NSError {
                print("Error: \(e.localizedDescription)")
            }
            
            let removeBlock = viewController?.view.raft.show(.loading)
            encodeVideo(at: videoURL) { (result, error) in
                removeBlock?()
                guard let result = result else {
                    self.completionBlock?(nil)
                    return
                }
                self.completionBlock?(Result(image: thumbnail, url: URL(string: result.absoluteString)))
            }
        case .defaultImage:
            self.completionBlock?(Result(image: info[.originalImage] as? UIImage, url: nil))
        case .squareImage:
            self.completionBlock?(Result(image: info[.editedImage] as? UIImage, url: nil))
        }
    }
    
//    func showError(errorMsg: String? = nil) {
//        if errorMsg == nil {
//            Toast.showToast(alertType: .warnning, message: NSLocalizedString("Oops! Something’s wrong.", comment: ""))
//        } else {
//            Toast.showToast(alertType: .warnning, message: errorMsg!)
//        }
//    }
    
}

extension ImagePickerManager {
    func encodeVideo(at videoURL: URL, completionHandler: ((URL?, Error?) -> Void)?) {
        let avAsset = AVURLAsset(url: videoURL, options: nil)
        
        //Create Export session
        guard let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            completionHandler?(nil, nil)
            return
        }
        let startDate = Date()
        //Creating temp path to save the converted video
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory.appendingPathComponent("rendered-Video.mp4")
        
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                completionHandler?(nil, error)
            }
        }
        
        exportSession.outputURL = filePath
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession.timeRange = range
        
        exportSession.exportAsynchronously(completionHandler: {() -> Void in
            mainQueueDispatchAsync {
                switch exportSession.status {
                case .failed:
                    print(exportSession.error ?? "NO ERROR")
                    completionHandler?(nil, exportSession.error)
                case .cancelled:
                    print("Export canceled")
                    completionHandler?(nil, nil)
                case .completed:
                    //Video conversion finished
                    let endDate = Date()
                    
                    let time = endDate.timeIntervalSince(startDate)
                    print(time)
                    print("Successful!")
                    print(exportSession.outputURL ?? "NO OUTPUT URL")
                    completionHandler?(exportSession.outputURL, nil)
                    
                default: break
                }
            }
        })
    }
    
    func deleteFile(_ filePath: String) {
        deleteFile(URL(fileURLWithPath: filePath))
    }
    
    func deleteFile(_ filePath: URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        } catch {
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
}

extension ImagePickerManager.PickerType {
    var allowsEditing: Bool {
        switch self {
        case .squareImage:
            return true
        default:
            return false
        }
    }
}
