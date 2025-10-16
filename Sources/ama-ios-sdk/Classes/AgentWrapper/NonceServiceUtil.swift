//
//  NonceService.swift
//  dataWallet
//
//  Created by iGrant on 09/06/25.
//

import Foundation
import eudiWalletOidcIos

class NonceServiceUtil {
    
    public func fetchNonce(accessTokenResponse: TokenResponse?, nonceEndPoint: String?) async -> String? {
        var nonce: String? = nil
        if accessTokenResponse?.cNonce == nil {
            nonce = await NonceService.shared.fetchNonceEndpoint(accessToken: accessTokenResponse?.accessToken ?? "", nonceEndPoint: nonceEndPoint)
        } else {
            nonce = accessTokenResponse?.cNonce
        }
        return nonce
    }
    
}
