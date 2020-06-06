//
//  SpeechRecognizer.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/4.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Speech
import Path
import SwiftyUserDefaults

fileprivate struct EmojiModel: Codable {
    let keywords: [String]
    let char: String
    let category: String
    
    private enum CodingKeys: String, CodingKey {
        case keywords
        case char
//        case fitzpatrickScale = "fitzpatrick_scale"
        case category
    }
}

class SpeechRecognizer {
    static let `default` = SpeechRecognizer()
    var didRecongnizedHandler: ((String?) -> Void)?
    var didRecongnizedEmojiHandler: (([String]) -> Void)?
    
    private var paths: [String] = []
    private var isStart: Bool = false
    private var emojiMaps: [String: String] = [:]
    
    init() {
        dispatchGlobalAsync {
            self.parseEmojiFile()
        }
    }
    
    var isAvaliable: Bool {
        return SFSpeechRecognizer(locale: Locale(identifier: "en_US"))?.isAvailable ?? false
    }
    
    func requestAuthorize(_ completionHandler: ((SFSpeechRecognizerAuthorizationStatus) -> Void)? = nil) {
        guard SFSpeechRecognizer.authorizationStatus() != .authorized else {
            completionHandler?(.authorized)
            return
        }
        SFSpeechRecognizer.requestAuthorization { authStatus in
            completionHandler?(authStatus)
        }
    }
    
    func add(file path: String) {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
            !emojiMaps.isEmpty else {
            return
        }
        paths.removeAll()
        paths.append(path)
        cdPrint("[SpeechRecognizer]- add queue: \(paths)")
    }
    
    func startIfNeed() {
        cdPrint("[SpeechRecognizer]- startIfNeed queue: \(paths)")

        guard let path = paths.first, !isStart else {
            return
        }
        start(with: path)
    }
    
    func removeFileFromQueue(path : String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            cdPrint("[SpeechRecognizer]- remove item error: \(error)")
        }
        paths.removeElement(ifExists: { $0 == path })
        startIfNeed()
    }
    
    func start(with filePath: String) {
        isStart = true
//        let recognizer = SFSpeechRecognizer(locale: Locale.current)
//        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
        cdPrint("[SpeechRecognizer] - will start: \(filePath)")
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US")) else {
            isStart = false
            removeFileFromQueue(path: filePath)
            cdPrint("[SpeechRecognizer] - can't get SFSpeechRecognizer: \(filePath)")
            return
        }
        let url = URL(fileURLWithPath: filePath)
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        if #available(iOS 13.0, *) {
            recognizer.supportsOnDeviceRecognition = true
//            request.requiresOnDeviceRecognition = true
        }
        cdPrint("[SpeechRecognizer] - start: \(filePath)")
//        NSLog("[SpeechRecognizer] - start: %@", filePath)

        let emojiMaps = self.emojiMaps
        var recognizedEmojis: [String] = []
        recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
            if error == nil, let isFinal = result?.isFinal {
                if let string = result?.bestTranscription.formattedString {
                    cdPrint("[SpeechRecognizer] - recognitionTask result: %@", string)
                    //match
                    let emojiChars = string.lowercased().split(bySeparator: " ")
                            .compactMap { emojiMaps[$0] }
//                    emojiChars.removeDuplicates()
                    var newChars = recognizedEmojis
                    newChars.append(contentsOf: emojiChars)
                    newChars.removeDuplicates()
                    if recognizedEmojis != newChars {
                        recognizedEmojis = newChars
                        self?.didRecongnizedHandler?(result?.bestTranscription.formattedString)
                        self?.didRecongnizedEmojiHandler?(emojiChars)
                    }
                }
                if isFinal {
                    self?.isStart = false
                    self?.removeFileFromQueue(path: filePath)
                }
            } else {
                NSLog("[SpeechRecognizer] - error: %@", String(describing: error?.localizedDescription))
//                cdPrint("[SpeechRecognizer] - error: \(String(describing: error?.localizedDescription))")
                self?.isStart = false
                self?.removeFileFromQueue(path: filePath)
            }
        })
    }
}

private extension SpeechRecognizer {
    func parseEmojiFile() {
        if let cachedMaps = Defaults[\.emojiMaps] as? [String: String],
            !cachedMaps.isEmpty {
            self.emojiMaps = cachedMaps
            return
        }

        guard let emojiFile = Bundle.main.path(forResource: "emojis", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: emojiFile.string), options: .mappedIfSafe),
            let dict = try? data.jsonObject() as? [String: Any] else {
            return
        }
        
        var result: [String: String] = [:]
        dict.values.forEach { item in
            guard let value = item as? [String: Any],
                let char = value["char"] as? String,
                let keywords = value["keywords"] as? [String] else {
                return
            }
            keywords.forEach { item in
                if result[item] == nil {
                    result[item] = char
                }
            }
        }
        Defaults[\.emojiMaps] = result
        self.emojiMaps = result
    }
}
