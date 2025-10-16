//
//  AccessTokenEBSIClient.swift
//  dataWallet
//
//  Created by sreelekh N on 14/07/22.
//

import Foundation

protocol AccessTokenEBSIClientProtocol: AccessTokenEBSIClient {
    func getAuthenticationRequests(token: String) async -> Result<AuthenticationRequestsModel?, NetworkResponse>
    func verifyAuthenticationRequests(did: String) async -> Result<VerifyAuthResponseModel?, NetworkResponse>
}

final class AccessTokenEBSIClient: HTTPClient, AccessTokenEBSIClientProtocol {
    
    func getAuthenticationRequests(token: String) async -> Result<AuthenticationRequestsModel?, NetworkResponse> {
        let header = ["Authorization" : "Bearer \(token)",
                      "Conformance": NSUUID().uuidString.lowercased()
        ]
        let param = AuthenticationRequestsEncodable(scope: "openid did_authn")
        return await serverRequest(url: .authorization, decodingType: AuthenticationRequestsModel.self, params: param, header: header)
    }
    
    func verifyAuthenticationRequests(did: String) async -> Result<VerifyAuthResponseModel?, NetworkResponse> {
        return await serverRequest(url: .verifyAuthRequest(did: did), decodingType: VerifyAuthResponseModel.self)
    }
    
    func getAuthenticationResponse(bearerToken: String, jwtToken: String, endPoint: String) async -> Result<AuthenticationRequestsModel?, NetworkResponse> {
        let header = ["Authorization" : "Bearer \(bearerToken)",
                      "Conformance": NSUUID().uuidString.lowercased()
        ]
        let param = ["id_token" : jwtToken]
        return await serverRequest(url: .getAuthenticationResponse(endPoint: endPoint), decodingType: AuthenticationRequestsModel.self, params: param, header: header)
    }
}
