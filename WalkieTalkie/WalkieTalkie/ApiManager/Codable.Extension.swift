//
//  Codable.Extension.swift
//  Moya-Cuddle
//
//  Created by Wilson-Yuan on 2019/12/25.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation

func decoderCatcher(_ block: (() throws -> Void)) {
    do {
        try block()
    } catch let DecodingError.keyNotFound(key, context) {
        print("keyNotFound- key:\(key), context: \(context)")
    } catch let DecodingError.typeMismatch(type, context) {
        print("typeMismatch- type:\(type), context: \(context)")
    } catch let DecodingError.valueNotFound(type, context) {
        print("valueNotFound- type:\(type), context: \(context)")
    } catch let DecodingError.dataCorrupted(context) {
        print("dataCorrupted- context: \(context)")
    } catch {
        print("decode error: \(error.localizedDescription)")
    }
}

func encoderCatcher(_ block: (() throws -> Void)) {
    do {
        try block()
    } catch let EncodingError.invalidValue(value, context) {
        print("[EncodingError.invalidValue]: value: \(value), context: \(context)")
    } catch {
        print("[EncodingError]: \(error)")
    }
}
