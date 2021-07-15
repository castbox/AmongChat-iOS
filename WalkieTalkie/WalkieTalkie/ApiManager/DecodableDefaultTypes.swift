//
//  DecodableDefaultTypes.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/7/8.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

protocol DecodableDefaultSource {
    associatedtype Value: Decodable
    static var defaultValue: Value { get }
}

enum DecodableDefaultTypes { }

extension DecodableDefaultTypes {
    
    @propertyWrapper
    struct Wrapper<Source: DecodableDefaultSource> {
        typealias Value = Source.Value
        var wrappedValue = Source.defaultValue
    }
    
}

extension DecodableDefaultTypes.Wrapper: Decodable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Value.self)
    }
    
}

extension DecodableDefaultTypes.Wrapper: Encodable where Value: Encodable {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension DecodableDefaultTypes.Wrapper: Equatable where Value: Equatable {}
extension DecodableDefaultTypes.Wrapper: Hashable where Value: Hashable {}

extension KeyedDecodingContainer {
    
    func decode<T>(_ type: DecodableDefaultTypes.Wrapper<T>.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> DecodableDefaultTypes.Wrapper<T> {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
    
}

extension DecodableDefaultTypes {
    
    typealias List = Decodable & ExpressibleByArrayLiteral
    typealias Map = Decodable & ExpressibleByDictionaryLiteral
    
    enum Sources {
        enum True: DecodableDefaultSource {
            static var defaultValue: Bool { true }
        }
        
        enum False: DecodableDefaultSource {
            static var defaultValue: Bool { false }
        }
        
        enum EmptyString: DecodableDefaultSource {
            static var defaultValue: String { "" }
        }
        
        enum EmptyList<T: List>: DecodableDefaultSource {
            static var defaultValue: T { [] }
        }
        
        enum EmptyMap<T: Map>: DecodableDefaultSource {
            static var defaultValue: T { [:] }
        }
        
        enum ZeroNumeric<T: Numeric & Decodable>: DecodableDefaultSource {
            static var defaultValue: T { 0 }
        }
    }
}

extension DecodableDefaultTypes {
    
    typealias True = Wrapper<Sources.True>
    typealias False = Wrapper<Sources.False>
    typealias EmptyString = Wrapper<Sources.EmptyString>
    typealias EmptyList<T: List> = Wrapper<Sources.EmptyList<T>>
    typealias EmptyMap<T: Map> = Wrapper<Sources.EmptyMap<T>>
    typealias ZeroNumeric<T: Numeric & Decodable> = Wrapper<Sources.ZeroNumeric<T>>
}

struct XXXXXXXDemonstrationExample {
    @DecodableDefaultTypes.True var flag: Bool
}
