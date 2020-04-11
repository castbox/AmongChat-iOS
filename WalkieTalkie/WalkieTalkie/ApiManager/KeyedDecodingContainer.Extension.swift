//
//  KeyedDecodingContainer.Extension.swift
//  Moya-Cuddle
//
//  Created by Wilson-Yuan on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import UIKit

extension KeyedDecodingContainer {
    
    func decodeCGFloat(_ key: K) throws -> CGFloat {
        do {
            let d = try decodeDouble(key)
            return CGFloat(d)
        } catch {
            throw error
        }
    }
    
    func decodeDouble(_ key: K) throws -> Double {
        do {
            return try decode(Double.self, forKey: key)
        } catch {
            if let i = try? decode(Int.self, forKey: key) {
                return Double(i)
            }
            if let s = try? decode(String.self, forKey: key), let d = Double(s) {
                return d
            }
            if let b = try? decode(Bool.self, forKey: key) {
                return b ? 1.0 : 0.0
            }
            throw error
        }
    }
    
    func decodeInt(_ key: K) throws -> Int {
        do {
            return try decode(Int.self, forKey: key)
        } catch {
            if let d = try? decode(Double.self, forKey: key) {
                return Int(d)
            }
            if let s = try? decode(String.self, forKey: key), let i = Int(s) {
                return i
            }
            if let b = try? decode(Bool.self, forKey: key) {
                return b ? 1 : 0
            }
            throw error
        }
    }
    
    func decodeString(_ key: K) throws -> String {
        do {
            return try decode(String.self, forKey: key)
        } catch {
            if let i = try? decode(Int.self, forKey: key) {
                return String(i)
            }
            if let d = try? decode(Double.self, forKey: key) {
                return NSDecimalNumber(value: d).stringValue
            }
            if let b = try? decode(Bool.self, forKey: key) {
                return b ? "true" : "false"
            }
            throw error
        }
    }
    
    func decodeBool(_ key: K) throws -> Bool {
        do {
            return try decode(Bool.self, forKey: key)
        } catch {
            if let s = try? decode(String.self, forKey: key) {
                if s.isEmpty || s == "0" || s.lowercased() == "false" {
                    return false
                }
                return true
            }
            if let i = try? decode(Int.self, forKey: key) {
                return (i == 0) ? false : true
            }
            if let d = try? decode(Double.self, forKey: key) {
                return (d == 0.0) ? false : true
            }
            throw error
        }
    }
    
    func decodeDate(_ key: K) throws -> Date {
        guard let date = try decodeDateIfPresent(key) else {
            let context = DecodingError.Context(codingPath: [key], debugDescription: "No value associated with key `\(key)`")
            throw DecodingError.keyNotFound(key, context)
        }
        return date
    }
    
}

// MARK: - ignore `DecodingError.keyNotFound` exception, return `nil` if not match key
extension KeyedDecodingContainer {
    
    func decodeCGFloatIfPresent(_ key: K) throws -> CGFloat? {
        if let d = try decodeDoubleIfPresent(key) {
            return CGFloat(d)
        }
        return nil
    }
    
    func decodeDoubleIfPresent(_ key: K) throws -> Double? {
        do {
            return try decodeIfPresent(Double.self, forKey: key)
        } catch {
            // Int -> Double
            do {
                if let i = try decodeIfPresent(Int.self, forKey: key) {
                    return Double(i)
                }
            } catch {}
            // String -> Double
            do {
                if let s = try decodeIfPresent(String.self, forKey: key) {
                    return Double(s)
                }
            } catch {}
            // Bool -> Double
            do {
                if let b = try decodeIfPresent(Bool.self, forKey: key) {
                    return b ? 1.0 : 0.0
                }
            } catch {}
            
            // failure
            throw error
        }
    }
    
    func decodeIntIfPresent(_ key: K) throws -> Int? {
        do {
            return try decodeIfPresent(Int.self, forKey: key)
        } catch {
            // Double -> Int
            do {
                if let d = try decodeIfPresent(Double.self, forKey: key) {
                    return Int(d)
                }
            } catch {}
            // String -> Int
            do {
                if let s = try decodeIfPresent(String.self, forKey: key) {
                    return Int(s)
                }
            } catch {}
            // Bool -> Int
            do {
                if let b = try decodeIfPresent(Bool.self, forKey: key) {
                    return b ? 1 : 0
                }
            } catch {}
            // decode failure.
            throw error
        }
    }
    
    func decodeStringIfPresent(_ key: K) throws -> String? {
        do {
            return try decodeIfPresent(String.self, forKey: key)
        } catch {
            // Int -> String
            do {
                if let i = try decodeIfPresent(Int.self, forKey: key) {
                    return String(i)
                }
            } catch {}
            // Double -> String
            do {
                if let d = try decodeIfPresent(Double.self, forKey: key) {
                    return String(d)
                }
            } catch {}
            // Bool -> String
            do {
                if let b = try decodeIfPresent(Bool.self, forKey: key) {
                    return b ? "true" : "false"
                }
            } catch {}
            // decode failure.
            throw error
        }
    }
    
    func decodeBoolIfPresent(_ key: K) throws -> Bool? {
        do {
            return try decodeIfPresent(Bool.self, forKey: key)
        } catch {
            // String -> Bool
            do {
                if let s = try decodeIfPresent(String.self, forKey: key) {
                    if s.isEmpty || s == "0" || s.lowercased() == "false" {
                        return false
                    }
                    return true
                }
            } catch {}
            // Int -> Bool
            do {
                if let i = try decodeIfPresent(Int.self, forKey: key) {
                    return (i == 0) ? false : true
                }
            } catch {}
            // Double -> Bool
            do {
                if let d = try decodeIfPresent(Double.self, forKey: key) {
                    return (d == 0.0) ? false : true
                }
            } catch {}
            // decode failure.
            throw error
        }
    }
    
    func decodeCGSizeIfPresent(_ key: K) throws -> CGSize? {
        do {
            return try decodeIfPresent(CGSize.self, forKey: key)
        } catch {
            do {
                if let s = try decodeIfPresent(String.self, forKey: key) {
                    for seprator in ["x", ",", "X"] {
                        let array = s.components(separatedBy: seprator)
                        if array.count == 2 {
                            if let w = Double(array.first!), let h = Double(array.last!) {
                                return CGSize(width: w, height: h)
                            }
                        }
                    }
                }
            } catch {}
            throw error
        }
    }
    
    func decodeDateIfPresent(_ key: K) throws -> Date? {
        do {
            return try decodeIfPresent(Date.self, forKey: key)
        } catch {
            if let s = try? decode(String.self, forKey: key) {
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                for dateFormat in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
                    formatter.dateFormat = dateFormat
                    guard let date = formatter.date(from: s) else { continue }
                    return date
                }
            }
            throw error
        }
    }
}
