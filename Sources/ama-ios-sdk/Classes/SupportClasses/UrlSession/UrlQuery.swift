//
//  Urls.swift
//  Ramz
//
//  Created by sreelekh N on 05/12/21.
//

import Foundation

struct AppBase {
    static let baseUrl = "https://api-conformance.ebsi.eu/"
}

enum UrlQuery {
    case authorization
    case verifyAuthRequest(did: String)
    case getAuthenticationResponse(endPoint: String)
    
    var rawUrl: String {
        switch self {
        case .authorization:
            return AppBase.baseUrl + "authorisation/v1/authentication-requests"
        case .verifyAuthRequest(let did):
            return AppBase.baseUrl + "did-registry/v2/identifiers/\(did)"
        case .getAuthenticationResponse(let endPoint):
            return endPoint
        }
    }
    
    var method: NetworkMethod {
        switch self {
        case .authorization:
            return .post
        case .verifyAuthRequest:
            return .get
        case .getAuthenticationResponse:
            return .post
        }
    }
}
