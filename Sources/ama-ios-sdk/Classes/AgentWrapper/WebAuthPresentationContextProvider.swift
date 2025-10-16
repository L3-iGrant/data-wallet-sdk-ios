//
//  WebAuthPresentationContextProvider.swift
//  dataWallet
//
//  Created by iGrant on 28/08/25.
//

import Foundation
import AuthenticationServices

class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first ?? ASPresentationAnchor()
  }
}
