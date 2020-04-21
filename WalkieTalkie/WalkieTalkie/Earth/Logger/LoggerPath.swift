//
//  LoggerPath.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/21.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

protocol LoggerPath {
    
    associatedtype Node
    
    var nodes: [Node] { get }
    
    init(nodes: [Node])
    
    @discardableResult
    static func start(with start: Node) -> Self
    
    @discardableResult
    func pass(_ inter: Node) -> Self?
    
    func validate(node: Node, after nodes: [Node]) -> (valid: Bool, end: Bool)
    
    func log()
    
}

extension LoggerPath {
    
    @discardableResult
    func pass(_ inter: Node) -> Self? {
        
        let rt = validate(node: inter, after: self.nodes)
        
        if rt.valid {
            
            var nodes = self.nodes
            nodes += [inter]
            let new = type(of: self).init(nodes: nodes)
            
            if rt.end {
                new.log()
                return nil
            } else {
                return new
            }
        }
        
        if (self.nodes.count == 0) {
            assert(rt.valid, "start with wrong start")
        }
        return nil
    }
    
    @discardableResult
    static func start(with start: Node) -> Self {
        let path = self.init(nodes: [])
        let new = path.pass(start)
        return new ?? path
    }
}

class LoggerPathReceiver<Path: LoggerPath> {
    
    private(set) var paths: [Path] = []
    var handle: ((Path)->[Path])?
    
    final func reset() {
        self.paths = []
    }
    
    final func receive(paths: [Path]) {
        
        guard let handle = handle else { return }
        
        self.paths = self.paths + paths.map { (path) -> [Path] in
            return handle(path)
            
            }.flatMap({ (paths) -> [Path] in
                return paths
            })
    }
    
    final func receive(path: Path) {
        self.receive(paths: [path])
    }
    
    final func append(paths: [Path]) {
        self.paths.append(contentsOf: paths)
    }
    
    final func append(path: Path) {
        self.paths.append(path)
    }
    
    @discardableResult
    final func pass(node: Path.Node) -> Self {
        for path in self.paths {
            path.pass(node)
        }
        
        return self
    }
    
    func receive(another receiver: LoggerPathReceiver<Path>) {
        self.receive(paths: receiver.paths)
    }
}
