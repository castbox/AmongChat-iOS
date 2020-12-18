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
        cdPrint("[decoderCatcher] keyNotFound- key:\(key), context: \(context)")
    } catch let DecodingError.typeMismatch(type, context) {
        cdPrint("[decoderCatcher] typeMismatch- type:\(type), context: \(context)")
    } catch let DecodingError.valueNotFound(type, context) {
        cdPrint("[decoderCatcher] valueNotFound- type:\(type), context: \(context)")
    } catch let DecodingError.dataCorrupted(context) {
        cdPrint("[decoderCatcher] dataCorrupted- context: \(context)")
    } catch {
        cdPrint("[decoderCatcher] decode error: \(error.localizedDescription)")
    }
}

func encoderCatcher(_ block: (() throws -> Void)) {
    do {
        try block()
    } catch let EncodingError.invalidValue(value, context) {
        cdPrint("[EncodingError.invalidValue]: value: \(value), context: \(context)")
    } catch {
        cdPrint("[EncodingError]: \(error)")
    }
}

