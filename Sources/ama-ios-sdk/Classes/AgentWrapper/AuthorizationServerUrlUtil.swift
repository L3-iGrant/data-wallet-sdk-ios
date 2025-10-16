//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 18/08/25.
//

import Foundation
import eudiWalletOidcIos

public class AuthorizationServerUrlUtil {
    
    func getAuthorizationServerUrl(issuerConfig: IssuerWellKnownConfiguration?, credentialOffer: CredentialOffer?) -> String? {
        var authServerUrl: String? = nil
        if issuerConfig?.authorizationServer?.count ?? 0 > 1 {
            let credentialAuthServer = credentialOffer?.grants?.authorizationCode?.authorizationServer
            authServerUrl = issuerConfig?.authorizationServer?.first(where: { $0 == credentialAuthServer })
            if credentialAuthServer == nil {
                authServerUrl = issuerConfig?.authorizationServer?.first
            }
            if authServerUrl == nil {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Invalid Authorization URL")
                return nil
            }
        } else {
            authServerUrl = issuerConfig?.authorizationServer?.first
        }
        return authServerUrl
    }
    
}

