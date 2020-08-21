//
//  Debug.swift
//  CastboxDebuger
//
//  Created by lazy on 2019/3/4.
//

import Foundation
import SwiftyBeaver
import SSZipArchive

public let mlog = Debug.self

public struct Debug {
    
    public static let filename: String  = "\(UUID().uuidString).zip"
    private static let password: String = "Castbox123"
    fileprivate static let keepLogCount = 7
    private static let minimumDiskSpaceRequired = 200 * 1024 * 1024 //200MB
    
    private static let logger: SwiftyBeaver.Type = {
        let logger = SwiftyBeaver.self
        logger.addDestination(file)
        #if DEBUG
        logger.addDestination(console)
        #endif
        return logger
    }()
    private static let file: FileDestination = {
        let file = FileDestination()
        if let logDir = logDir {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            file.logFileURL = logDir.appendingPathComponent("\(dateString).log", isDirectory: false)
        }
        file.minLevel = .info
        file.format = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l -$X- $M"
        /// warning: 采用异步写入，调用collect之后立即压缩会导致当次的collect操作丢失
        file.asynchronously = true
        return file
    }()
    
    private static let console: ConsoleDestination = {
        let d = ConsoleDestination()
        d.format = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l -$X- $M"
        d.minLevel = .verbose
        return d
    }()
    
    private static let logDir: URL? = {
        if let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let logDir = cachesDir.appendingPathComponent("SwiftyBeaverLogger", isDirectory: true)
            if FileManager.default.fileExists(atPath: logDir.path) == false {
                do {
                    try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    return nil
                }
            } else if let files = try? FileManager.default.contentsOfDirectory(at: logDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                //目录已存在，先行删除超期的log
                DispatchQueue.global().async {
                    files.removeExpiredLogs()
                }
            }
            return logDir
        } else {
            return nil
        }
    }()
    
    private static func log(_ content: Any) {
        logger.debug(content)
    }
    
    // 压缩后返回文件路径
    public static func zip() -> URL? {
        
        let manager = FileManager.default
        
        // 1.检查是否有旧的压缩文件，有的话删除旧的压缩文件
        guard let fileURL = file.logFileURL else { return nil }
        let zipFileURL = fileURL.deletingLastPathComponent().appendingPathComponent(filename)
        if manager.fileExists(atPath: fileURL.path) {
            do {
                try manager.removeItem(at: zipFileURL)
            } catch {
                
            }
        }
        // 2.压缩文件
        guard let files = logFiles(),
            SSZipArchive.createZipFile(atPath: zipFileURL.path,
                                         withFilesAtPaths: files,
                                         withPassword: password) else {
                                            // 压缩失败
                                            return nil
        }
        
        if fileURL.deletingLastPathComponent().path != logDir?.path {
            // 3.清空SwiftyBeaver.log文件
            clear()
        }
        
        return zipFileURL
    }
    
    // 清空SwiftyBeaver.log文件，清除时机还不确定
    @discardableResult
    private static func clear() -> Bool {
        return file.deleteLogFile()
    }
    
    private static func logFiles() -> [String]? {
        let manager = FileManager.default
        
        guard let fileURL = file.logFileURL else { return nil }
        
        let fileDir = fileURL.deletingLastPathComponent()
        
        guard let logDir = logDir,
            fileDir.path == logDir.path,
            let files = try? manager.contentsOfDirectory(at: logDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            else {
                return [fileURL.path]
        }
        
        //删除已存在的.zip
        let _ = files.filter { $0.pathExtension == "zip" }
            .compactMap { (url) -> Void in
                if manager.fileExists(atPath: url.path) {
                    do {
                        try manager.removeItem(at: url)
                    } catch {
                        #if DEBUG
                        NSLog("==debugger== remove file: \(url.absoluteString) \n error: \(error)")
                        #endif
                    }
                }
        }
        
        return files.removeExpiredLogs().compactMap { $0.path }
    }
}

fileprivate extension Array where Element == URL {
    
    @discardableResult
    func removeExpiredLogs() -> [Element] {
        let manager = FileManager.default
        //筛出.log，逆序排列，取出前7条，其余删除。
        let sortedFiles = self.filter({ $0.pathExtension == "log" })
            .sorted(by: { $0.lastPathComponent.lowercased() > $1.lastPathComponent.lowercased() })
        let _ = sortedFiles.dropFirst(Debug.keepLogCount).compactMap { (url) -> Void in
            if manager.fileExists(atPath: url.path) {
                do {
                    try manager.removeItem(at: url)
                } catch  {
                    #if DEBUG
                    NSLog("==debugger== remove file: \(url.absoluteString) \n error: \(error)")
                    #endif
                }
            }
        }
        
        return sortedFiles.prefix(Debug.keepLogCount).compactMap { $0 }
    }
}

extension Debug {
    
    public static func verbose(_ message: Any,
                               _ file: String = #file,
                               _ function: String = #function,
                               line: Int = #line,
                               context: Any? = nil) {
        safeLogging {
            logger.verbose(message, file, function, line: line, context: context)
        }
    }

    public static func debug(_ message: Any,
                             _ file: String = #file,
                             _ function: String = #function,
                             line: Int = #line,
                             context: Any? = nil) {
        safeLogging {
            logger.debug(message, file, function, line: line, context: context)
        }
    }

    public static func info(_ message: Any,
                            _ file: String = #file,
                            _ function: String = #function,
                            line: Int = #line,
                            context: Any? = nil) {
        safeLogging {
            logger.info(message, file, function, line: line, context: context)
        }
    }

    public static func warning(_ message: Any,
                               _ file: String = #file,
                               _ function: String = #function,
                               line: Int = #line,
                               context: Any? = nil) {
        safeLogging {
            logger.warning(message, file, function, line: line, context: context)
        }
    }

    public static func error(_ message: Any,
                             _ file: String = #file,
                             _ function: String = #function,
                             line: Int = #line,
                             context: Any? = nil) {
        safeLogging {
            logger.error(message, file, function, line: line, context: context)
        }
    }
    
    private static func safeLogging(action: () -> Void) {
        #if DEBUG
        action()
        #else
        guard let totalDiskSpaceInBytes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[FileAttributeKey.systemFreeSize] as? Int,
        totalDiskSpaceInBytes > minimumDiskSpaceRequired else {
            return
        }
        action()
        #endif
    }
}
