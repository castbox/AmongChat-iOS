//
//  FileManagerExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension FileManager {
    static var voiceFileDirectory: String? {
        let voiceDic = CachesDirectory()+"/voice"
        let (isSuccess, error) = createFolder(folderPath: voiceDic)
        guard isSuccess else {
            cdPrint("error: \(error)")
            return nil
        }
        return voiceDic
    }
    
    static func voiceFilePath(with name: String) -> String? {
        //create doctory
        guard let fold = voiceFileDirectory else {
            return nil
        }
        return fold.appendingPathComponent(name.contains(".aac") ? name: name + ".aac")
    }
    
    static func gifFilePath(with name: String) -> String? {
        //create doctory
        guard let fold = voiceFileDirectory else {
            return nil
        }
        return fold.appendingPathComponent(name.contains(".gif") ? name: name + ".gif")
    }
    
    //relativepath
    static func relativePath(of absolutePath: String) -> String {
        return absolutePath.replacingOccurrences(of: CachesDirectory(), with: "")
    }
    
    static func absolutePath(for relativePath: String) -> String {
        if relativePath.starts(with: "/") {
            return CachesDirectory() + relativePath
        } else {
            return CachesDirectory() + "/" + relativePath
        }
    }
    
}
