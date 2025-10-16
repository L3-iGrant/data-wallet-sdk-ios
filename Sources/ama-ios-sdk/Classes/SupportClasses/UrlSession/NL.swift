//
//  NL.swift
//  SocialMob
//
//  Created by sreelekh N on 21/11/21.
//

import Foundation
struct DefaultEncodable: Encodable {}
struct DefaultDecodable: Decodable {}

struct GenericResponse: Decodable {
    var status: Int?
    var message: String?
    var data: MedicardiaGenericData?
    var msgHeader: Int?
    var isSuccess: Bool?
    var token: String?

    enum CodingKeys: String, CodingKey {
        case status, message, data
        case msgHeader = "msg_header"
        case isSuccess = "is_success"
        case token
    }
}

struct MedicardiaGenericData: Decodable {}

protocol HTTPClient {
    func serverRequest<T: Decodable, Q: Encodable>(url: UrlQuery,
                                                   decodingType: T.Type,
                                                   params: Q) async -> Result<T?, NetworkResponse>
    
    func serverRequest<T: Decodable, Q: Encodable>(url: UrlQuery,
                                                   decodingType: T.Type,
                                                   params: Q,
                                                   header: SessionHeaders) async -> Result<T?, NetworkResponse>
    
    func serverRequest<T: Decodable>(url: UrlQuery,
                                     decodingType: T.Type) async -> Result<T?, NetworkResponse>
    
    func serverRequest<T: Decodable>(url: UrlQuery,
                                     decodingType: T.Type,
                                     header: SessionHeaders) async -> Result<T?, NetworkResponse>
}

extension HTTPClient {
    
    func serverRequest<T: Decodable, Q: Encodable>(url: UrlQuery,
                                                   decodingType: T.Type,
                                                   params: Q) async -> Result<T?, NetworkResponse> {
        let client = NL()
        return await client.serverRequest(url: url, decodingType: decodingType, params: params)
    }
    
    func serverRequest<T: Decodable, Q: Encodable>(url: UrlQuery,
                                                   decodingType: T.Type,
                                                   params: Q,
                                                   header: SessionHeaders = nil) async -> Result<T?, NetworkResponse> {
        let client = NL()
        return await client.serverRequest(url: url, decodingType: decodingType, params: params, header: header)
    }
    
    func serverRequest<T: Decodable>(url: UrlQuery, decodingType: T.Type) async -> Result<T?, NetworkResponse> {
        let client = NL()
        return await client.serverRequest(url: url, decodingType: decodingType)
    }
    
    func serverRequest<T: Decodable>(url: UrlQuery, decodingType: T.Type, header: SessionHeaders = nil) async -> Result<T?, NetworkResponse> {
        let client = NL()
        return await client.serverRequest(url: url, decodingType: decodingType, header: header)
    }
}


struct NL {
    
    private let sessionLayer: UrlSessionLayer
    
    init() {
        sessionLayer = UrlSessionLayer()
    }
    
    func serverRequest<T: Decodable, Q: Encodable>(url: UrlQuery,
                                                   decodingType: T.Type,
                                                   params: Q,
                                                   header: SessionHeaders = nil) async -> Result<T?, NetworkResponse> {
        
        let headers: SessionHeaders = getBearerToken() ?? nil
        let compiled = headers?.merging(header ?? [:]) { (_, new) in new }
        return await sessionLayer.sendRequest(url: url, headers: compiled, params: params, decodingType: decodingType)
    }
    
    func serverRequest<T: Decodable>(url: UrlQuery,
                                     decodingType: T.Type,
                                     header: SessionHeaders = nil) async -> Result<T?, NetworkResponse> {
        
        let headers: SessionHeaders = getBearerToken() ?? nil
        let compiled = headers?.merging(header ?? [:]) { (_, new) in new }
        let def = DefaultEncodable()
        return await sessionLayer.sendRequest(url: url, headers: compiled, params: def, decodingType: decodingType)
    }
    
    private func getBearerToken() -> SessionHeaders? {
        return nil
    }
}

enum MetadataType: Decodable {
    case stringValue(String)
    case intValue(Int)
    case doubleValue(Double)
    case boolValue(Bool)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .stringValue(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .boolValue(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .doubleValue(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .intValue(value)
            return
        }
        throw DecodingError.typeMismatch(MetadataType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for ValueWrapper"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .stringValue(value):
            try container.encode(value)
        case let .boolValue(value):
            try container.encode(value)
        case let .intValue(value):
            try container.encode(value)
        case let .doubleValue(value):
            try container.encode(value)
        }
    }
    
    var rawValue: String {
        var result: String
        switch self {
        case let .stringValue(value):
            result = value
        case let .boolValue(value):
            result = String(value)
        case let .intValue(value):
            result = String(value)
        case let .doubleValue(value):
            result = String(Int(value))
        }
        return result
    }
    
    var intValue: Int? {
        var result: Int?
        switch self {
        case let .stringValue(value):
            result = Int(value)
        case let .intValue(value):
            result = value
        case let .boolValue(value):
            result = value ? 1 : 0
        case let .doubleValue(value):
            result = Int(value)
        }
        return result
    }
    
    var boolValue: Bool? {
        var result: Bool?
        switch self {
        case let .stringValue(value):
            result = Bool(value)
        case let .boolValue(value):
            result = value
        case let .intValue(value):
            result = Bool(truncating: value as NSNumber)
        case let .doubleValue(value):
            result = Bool(truncating: value as NSNumber)
        }
        return result
    }
}
