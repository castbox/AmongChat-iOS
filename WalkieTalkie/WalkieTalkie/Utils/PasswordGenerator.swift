//
//  PasswordGenerator.swift
//  Password Generator
//
//  Created by Neil Ang on 9/06/2014.
//  Copyright (c) 2014 Neil Ang. All rights reserved.
//
import Foundation

extension Array {
    func randomItem() -> Element? {
        guard count > 0  else { return nil }
        let idx = Int(arc4random_uniform(UInt32(count))) % count
        return self.safe(idx)
    }
    
    // Could contain duplicates
    func randomItems(total: Int) -> [Element] {
        var result: [Element] = []
        for _ in (0..<total) {
            if let item = randomItem() {
                result += [item]
            }
        }
        return result
    }
    
}

extension String {
    func split(bySeparator: String) -> Array<String> {
        if bySeparator.count < 1 {
            var items: [String] = []
            for c in self {
                items.append(String(c))
            }
            return items
        }
        return self.components(separatedBy: bySeparator)
    }
}

class PasswordGenerator {
    static let shared = PasswordGenerator()
//    let lowercaseSet = "abcdefghijklmnopqrstuvwxyz".split(bySeparator: "")
    let uppercaseSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(bySeparator: "")
    //    let symbolSet    = "!@#$%^&*?".split(bySeparator: "")
    let numberSet    = "0123456789".split(bySeparator: "")
    
    var numbers   = 4
//    var lowercase = 3
    var uppercase = 4
    //  var symbols   = 5
    var totalCount = 8
    
    func generate() -> String {
        var password: [String] = []
//        password += lowercaseSet.randomItems(total: lowercase)
        password += uppercaseSet.randomItems(total: uppercase)
        password += numberSet.randomItems(total: numbers)
        //    password += symbolSet.randomItems(total:symbols)
        return password.shuffled().reduce("", +)
    }
}
