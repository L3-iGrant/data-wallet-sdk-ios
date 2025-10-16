//
//  DataPodsUtils.swift
//  ama-ios-sdk
//
//  Created by iGrant on 24/04/25.
//

import Foundation
import UIKit
import CryptoKit
import JOSESwift
import WebKit
import KeychainSwift

class DataPodsUtils: NSObject {
    static var shared = DataPodsUtils()
    
    let redirectURI = "https://datawallet.abc/"
    var openIDConfig: [String: Any]?
    var codeVerifier: String = ""
    var codeChallenge: String = ""
    var webviewVC: WebViewViewController?
    var userProvidedURL:String {
        get{
            return UserDefaults.standard.value(forKey: "username_datapods") as? String ?? ""
        }
        set{
            UserDefaults.standard.setValue(newValue, forKey: "username_datapods")
        }
    }
    private var keyPair: (privateKey: P256.Signing.PrivateKey, publicKey: P256.Signing.PublicKey)? {
        didSet{
            saveKeyPairToUserDefaults(keyPair: keyPair)
        }
    }
    private var completion: ((String, Bool)->Void)?
    
    private override init() {
        super.init()
    }
    
    func clearData(){
        let keychain = KeychainSwift()
        keychain.delete("DataPodsPrivateKey")
        keychain.delete("DataPodsPublicKey")
        keychain.delete("datapods_access_token")
        keychain.delete("datapods_access_token_expire")
        
        UserDefaults.standard.removeObject(forKey: "podName")
    }
    
    func saveAccessToken(_ accessToken: String, expireIn: Double) {
        let keychain = KeychainSwift()
        keychain.set(accessToken, forKey: "datapods_access_token")
        keychain.set("\(expireIn)", forKey: "datapods_access_token_expire")
    }
    
    func saveRefreshToken(_ refreshToken: String) {
        let keychain = KeychainSwift()
        keychain.set(refreshToken, forKey: "datapods_refresh_token")
    }
    
    func getRefreshToken() -> String? {
        let keychain = KeychainSwift()
        return keychain.get("datapods_refresh_token")
    }
    
    func saveClientId(_ clientId: String) {
        let keychain = KeychainSwift()
        keychain.set(clientId, forKey: "datapods_clientId")
    }
    
    func saveClientSecret(_ clientSecret: String) {
        let keychain = KeychainSwift()
        keychain.set(clientSecret, forKey: "datapods_clientSecret")
    }
    
    func getClientId() -> String? {
        let keychain = KeychainSwift()
        return keychain.get("datapods_clientId")
    }
    
    func getClientSecret() -> String? {
        let keychain = KeychainSwift()
        return keychain.get("datapods_clientSecret")
    }
    
    private func saveKeyPairToUserDefaults(keyPair: (privateKey: P256.Signing.PrivateKey, publicKey: P256.Signing.PublicKey)?) {
        let keychain = KeychainSwift()
        if let keyPair = keyPair {
            let privateKeyData = keyPair.privateKey.rawRepresentation
            let publicKeyData = keyPair.publicKey.rawRepresentation
            
            keychain.set(privateKeyData, forKey: "DataPodsPrivateKey")
            keychain.set(publicKeyData, forKey: "DataPodsPublicKey")
        } else {
            keychain.delete("DataPodsPrivateKey")
            keychain.delete("DataPodsPublicKey")
        }
    }
    
    private func retrieveKeyPairFromUserDefaults() -> (privateKey: P256.Signing.PrivateKey, publicKey: P256.Signing.PublicKey)? {
        let keychain = KeychainSwift()
        if let privateKeyData = keychain.getData("DataPodsPrivateKey"),
           let publicKeyData = keychain.getData("DataPodsPublicKey"),
           let privateKey = try? P256.Signing.PrivateKey(rawRepresentation: privateKeyData),
           let publicKey = try? P256.Signing.PublicKey(rawRepresentation: publicKeyData) {
            return (privateKey: privateKey, publicKey: publicKey)
        }
        return nil
    }
    
    func getAccessToken() -> String? {
        let keychain = KeychainSwift()
        let accessToken = keychain.get("datapods_access_token")
        
        guard let expireIn = keychain.get("datapods_access_token_expire") else { return nil }

        if let doubleValue = Double(expireIn), doubleValue > Date().timeIntervalSince1970 {
            return accessToken
        } else {
            // Refreshing token when token expired
            guard let keyPair = generateKeyPair() else { return "" }
            let tokenEndpoint = "https://datapod.igrant.io/token"
            let dpopUniqueIdentifier = UUID().uuidString
            
            let publicKeyJWK = exportPublicKeyAsJWK(publickKey: keyPair.publicKey, keyID: dpopUniqueIdentifier) ?? [:]
            let header: [String: Any] = [
                "alg": "ES256",
                "typ": "dpop+jwt",
                "jwk": publicKeyJWK
            ]
            
            let claims: [String: Any] = [
                "htu": tokenEndpoint,
                "htm": "POST",
                "jti": dpopUniqueIdentifier,
                "iat": Int(Date().timeIntervalSince1970)
            ]
            let dpopJWT = generateJWT(privateKey: keyPair.privateKey, header: header, claims: claims) ?? ""
            debugPrint("DPoP JWT: \(dpopJWT)")
            
            // Exchange authorization code for access token
            let tokenInfo = exchangeAuthorizationCode(tokenEndpoint: tokenEndpoint, dpopJWT: dpopJWT, codeVerifier: codeVerifier, code: "", redirectURI: redirectURI, isRefresh: true)
            debugPrint("Access Token: \(tokenInfo?.accessToken ?? "")")
            let expireTime = Date().timeIntervalSince1970 + (tokenInfo?.expireIn ?? 0)
            self.saveAccessToken(tokenInfo?.accessToken ?? "",expireIn: expireTime)
            self.completion?(tokenInfo?.accessToken ?? "", true)
            
            return tokenInfo?.accessToken
        }
    }
    
    func openAuthorizationURL(url: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
            self.webviewVC = UIStoryboard(name:"ama-ios-sdk", bundle: Bundle.module).instantiateViewController( withIdentifier: "WebViewVC") as? WebViewViewController
            if let webviewVC =  self.webviewVC {
                webviewVC.clearWebViewCache()
                webviewVC.redirectDelegate = self
                webviewVC.urlString = url.absoluteString
                webviewVC.redirectUrl = self.redirectURI
                webviewVC.originatingFrom = .DataPods
                webviewVC.completionHandler = completion
                webviewVC.modalPresentationStyle = .formSheet
                if let nvc = UIApplicationUtils.shared.getTopVC()?.navigationController {
                    nvc.pushViewController(webviewVC, animated: true)
                } else {
                    UIApplicationUtils.shared.getTopVC()?.present(webviewVC, animated: true)
                }
            } else {
                print("")
            }
        })
    }
    
    func extractUserName(from urlString: String) -> String? {
        // Ensure the string is a valid URL
        guard let url = URL(string: urlString), let host = url.host else {
            return nil
        }
        
        // Split the host into components separated by "."
        let components = host.split(separator: ".")
        
        // We expect the first component to be the value we want to extract
        if components.count > 0, components[1] == "datapod", components[2] == "igrant" {
            return String(components[0])
        }
        
        return nil
    }

        
    func getAccessForUser(url: String, completion: ((String, Bool)->Void)? = nil){
        Task {
            var isExistingPodUser: Bool = false
            if let extractedValue = extractUserName(from: url) {
                debugPrint("Extracted value: \(extractedValue)")
                if let podName = UserDefaults.standard.string(forKey: "podName") {
                    if extractedValue == podName {
                        // Existing pod user
                        debugPrint("Existing pod")
                        isExistingPodUser = true
                    }
                }
            }
            
            if isExistingPodUser {
                //return accesstoken if valid
                if let accessToken = getAccessToken(){
                    completion?(accessToken, true)
                    return
                }
            }

            clearData()
            self.completion = completion
            let dataPodURL = obtainDataPodURL(userProvidedURL: url)
            debugPrint("DataPod URL: \(dataPodURL)")
            
            if let webIDDocument = try? await fetchWebIDDocument(dataPodURL: dataPodURL) {
                debugPrint("WebID Document: \(webIDDocument)")
                
                if let oidcIssuerURL = getOIDCIssuerURL(webIDDocument: webIDDocument) {
                    debugPrint("OIDC Issuer URL: \(oidcIssuerURL)")
                    
                    if let openIDConfig = try? await obtainOpenIDConfiguration(oidcIssuerURL: oidcIssuerURL) {
                        debugPrint("OpenID Configuration: \(openIDConfig)")
                        self.openIDConfig = openIDConfig
                        if let clientRegistration = performDynamicClientRegistration(oidcIssuerURL: oidcIssuerURL) {
                            debugPrint("Client Registration Response: \(clientRegistration)")
                            //1.5 Perform authorisation
                            codeVerifier = generateCodeVerifier() ?? ""
                            codeChallenge = generateCodeChallenge(codeVerifier: codeVerifier)
                            let authorizationEndpoint = openIDConfig["authorization_endpoint"] as? String ?? ""
                            let clientID = clientRegistration["client_id"] as? String ?? ""
                            let clientSecret = clientRegistration["client_secret"] as? String ?? ""
                            saveClientId(clientID)
                            saveClientSecret(clientSecret)
                            
                            if let authorizationURL = prepareAuthorizationURL(authorizationEndpoint: authorizationEndpoint, redirectURI: redirectURI, clientID: clientID, codeChallenge: codeChallenge) {
                                print("Authorization URL: \(authorizationURL)")
                                // Open the authorization URL in a web view or browser and handle the redirect URL
                                openAuthorizationURL(url: authorizationURL, completion: { success in
                                    if !success {
                                        completion?("", false)
                                    }
                                    
                                })
                            }
                        } else {
                            debugPrint("Failed to perform dynamic client registration")
                            clearData()
                            UIApplicationUtils.hideLoader()
                            UIApplicationUtils.showErrorSnackbar(message: "Failed to perform dynamic client registration")
                            completion?("", false)
                        }
                    } else {
                        debugPrint("Failed to obtain OpenID configuration")
                        clearData()
                        UIApplicationUtils.hideLoader()
                        UIApplicationUtils.showErrorSnackbar(message: "Failed to obtain OpenID configuration")
                        completion?("", false)
                    }
                } else {
                    debugPrint("Failed to get OIDC Issuer URL from WebID document")
                    clearData()
                    UIApplicationUtils.hideLoader()
                    UIApplicationUtils.showErrorSnackbar(message: "Failed to get OIDC Issuer URL from WebID document")
                    completion?("", false)
                }
            } else {
                debugPrint("Failed to fetch WebID document")
                clearData()
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Failed to fetch WebID document")
                completion?("", false)
            }
        }
    }
    
    func obtainDataPodURL(userProvidedURL: String) -> String {
        var dataPodURL = userProvidedURL
        
        if !dataPodURL.hasSuffix("/profile/card#me") {
            dataPodURL += "/profile/card#me"
        }
        
        return dataPodURL
    }
    
    func fetchWebIDDocument(dataPodURL: String) async throws -> String? {
        let urlString = "\(dataPodURL)"
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let webIDDocument = String(data: data, encoding: .utf8) {
                return webIDDocument
            } else {
                return nil
            }
        } catch {
            debugPrint("Failed to fetch WebID document: \(error)")
            return nil
        }
    }

    
    func getOIDCIssuerURL(webIDDocument: String) -> String? {
        let pattern = "solid:oidcIssuer\\s+(<[^>]+>)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: webIDDocument.utf16.count)
        if let match = regex.firstMatch(in: webIDDocument, options: [], range: range) {
            let nsRange = match.range(at: 1)
            if let range = Range(nsRange, in: webIDDocument) {
                var oidcIssuerURL = String(webIDDocument[range])
                oidcIssuerURL = oidcIssuerURL.replacingOccurrences(of: "<", with: "")
                oidcIssuerURL = oidcIssuerURL.replacingOccurrences(of: ">", with: "")
                return oidcIssuerURL
            }
        }
        
        return nil
    }
    
    func obtainOpenIDConfiguration(oidcIssuerURL: String) async throws -> [String: Any]? {
        let configURLString = "\(oidcIssuerURL)/.well-known/openid-configuration"
        guard let configURL = URL(string: configURLString) else {
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: configURL)
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return json
        } catch {
            debugPrint("Failed to parse OpenID configuration: \(error)")
            return nil
        }
    }
    
    func performDynamicClientRegistration(oidcIssuerURL: String) -> [String: Any]? {
        let registrationURLString = "\(oidcIssuerURL)/register"
        guard let registrationURL = URL(string: registrationURLString) else {
            return nil
        }
        
        let clientRegistration: [String: Any] = [
            "client_name": "Data Wallet",
            "application_type": "web",
            "redirect_uris": [redirectURI],
            "subject_type": "public",
            "token_endpoint_auth_method": "client_secret_basic",
            "id_token_signed_response_alg": "RS256",
            "grant_types": ["authorization_code", "refresh_token"]
        ]
        
        var request = URLRequest(url: registrationURL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: clientRegistration, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let semaphore = DispatchSemaphore(value: 0)
        var clientRegistrationResponse: [String: Any]?
        
        let task = session.dataTask(with: request) { (data, response, error) in
            defer { semaphore.signal() }
            
            if let error = error {
                debugPrint("Failed to perform dynamic client registration: \(error)")
                return
            }
            
            if let data = data {
                clientRegistrationResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return clientRegistrationResponse
    }
    
    func generateCodeVerifier() -> String? {
        let byteCount = 64
        let data = Data.randomData(ofSize: byteCount)
        return data.urlSafeBase64EncodedString()
    }
    
    func generateCodeChallenge(codeVerifier: String) -> String {
        guard let codeVerifierData = codeVerifier.data(using: .ascii) else {
            return ""
        }
        
        let codeChallengeData = SHA256.hash(data: codeVerifierData)
        let codeChallenge = codeChallengeData.withUnsafeBytes { pointer in
            return Data(pointer).urlSafeBase64EncodedString()
        }
        
        return codeChallenge
    }
    
    func prepareAuthorizationURL(authorizationEndpoint: String, redirectURI: String, clientID: String, codeChallenge: String) -> URL? {
        var components = URLComponents(string: authorizationEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "openid webid offline_access"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: codeChallenge)
        ]
        
        return components?.url
    }
    
    func handleRedirectURL(redirectURL: URL) -> String? {
        guard let code = redirectURL.queryParameters?["code"] else {
            return nil
        }
        return code
    }
    
    func generateJWT(privateKey: P256.Signing.PrivateKey, header: [String: Any], claims: [String: Any]) -> String? {
        
        guard let headerData = try? JSONSerialization.data(withJSONObject: header),
              let payloadData = try? JSONSerialization.data(withJSONObject: claims)
        else {
            return nil
        }
        
        let encodedHeader = headerData.urlSafeBase64EncodedString()
        let encodedPayload = payloadData.urlSafeBase64EncodedString()
        let jwt = "\(encodedHeader).\(encodedPayload)"
        
        
        guard let signature = try? privateKey.signature(for: jwt.data(using: .utf8)!)
        else {
            return nil
        }
        let encodedSignature = signature.rawRepresentation.urlSafeBase64EncodedString()
        return "\(jwt).\(encodedSignature)"
    }
    
    
    func exchangeAuthorizationCode(tokenEndpoint: String, dpopJWT: String, codeVerifier: String, code: String?, redirectURI: String, isRefresh: Bool = false) -> (accessToken: String, refreshToken: String?, expireIn: Double)? {
        
        var requestBody = [String:String]()
        let clientSecret = getClientSecret()
        let clientId = getClientId()
        
        if isRefresh {
            let refreshToken = getRefreshToken()
            requestBody = [
              "grant_type": "refresh_token",
              "refresh_token": refreshToken ?? "",
              "client_secret": clientSecret ?? "",
              "client_id": clientId ?? ""
            ]
        } else {
            requestBody =  [
                "grant_type": "authorization_code",
                "code_verifier": codeVerifier,
                "code": code ?? "",
                "client_id": clientId ?? "",
                "redirect_uri": redirectURI
            ]
        }
        
        let headers = [
            "DPoP": dpopJWT,
            "content-type": "application/x-www-form-urlencoded"
        ]
        
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = requestBody.queryParameters().data(using: .utf8)
        
        var accessToken: String?
        var refreshToken: String?
        var expireIn: Double?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                semaphore.signal()
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                return
            }
            
            let statusCode = httpResponse.statusCode
            print("Status code1: \(statusCode)")
            debugPrint("Response --- \(String(describing: String(data: data, encoding: .utf8)))")
            
            // Process the response data
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // Extract the access token and refresh token from the JSON response
                    accessToken = json["access_token"] as? String
                    refreshToken = json["refresh_token"] as? String
                    expireIn = json["expires_in"] as? Double
                    
                    if let accessToken = accessToken, let refreshToken = refreshToken {
                        // Print the access token and refresh token
                        debugPrint("Access Token: \(accessToken)")
                        debugPrint("Refresh Token: \(refreshToken)")
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
        task.resume()
        semaphore.wait()
        
        if isRefresh {
            if let accessToken = accessToken, let expireIn = expireIn {
                return (accessToken, "", expireIn)
            } else {
                return nil
            }
        } else {
            if let accessToken = accessToken, let refreshToken = refreshToken, let expireIn = expireIn {
                return (accessToken, refreshToken, expireIn)
            } else {
                return nil
            }
        }
    }
    
    
    func generateKeyPair() -> (privateKey: P256.Signing.PrivateKey, publicKey: P256.Signing.PublicKey)? {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        return (privateKey, publicKey)
    }
    
    func exportPublicKeyAsJWK(publickKey: P256.Signing.PublicKey, keyID: String) -> [String: Any]? {
        let publicKeyData = publickKey.x963Representation
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(publicKeyData as CFData, [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPublic
        ] as CFDictionary, &error) else {
            return nil
        }
        let jwk = try! ECPublicKey(publicKey: secKey,additionalParameters: ["kid" : keyID])
        return jwk.dictionary
    }
}

extension DataPodsUtils: WebViewRedirectDelegate {
    func handleRedirectURL(_ url: URL) {
        if url.absoluteString.contains(redirectURI),let keyPair = generateKeyPair(), let authorizationCode = handleRedirectURL(redirectURL: url){
            self.keyPair = keyPair
            debugPrint("Authorization Code: \(authorizationCode)")
            
            let tokenEndpoint = openIDConfig?["token_endpoint"] as? String ?? ""
            let dpopUniqueIdentifier = UUID().uuidString
            
            let publicKeyJWK = exportPublicKeyAsJWK(publickKey: keyPair.publicKey, keyID: dpopUniqueIdentifier) ?? [:]
            let header: [String: Any] = [
                "alg": "ES256",
                "typ": "dpop+jwt",
                "jwk": publicKeyJWK
            ]
            
            let claims: [String: Any] = [
                "htu": tokenEndpoint,
                "htm": "POST",
                "jti": dpopUniqueIdentifier,
                "iat": Int(Date().timeIntervalSince1970)
            ]
            let dpopJWT = generateJWT(privateKey: keyPair.privateKey, header: header, claims: claims) ?? ""
            debugPrint("DPoP JWT: \(dpopJWT)")
            
            // Exchange authorization code for access token
            let tokenInfo = exchangeAuthorizationCode(tokenEndpoint: tokenEndpoint, dpopJWT: dpopJWT, codeVerifier: codeVerifier, code: authorizationCode, redirectURI: redirectURI)
            debugPrint("Access Token: \(tokenInfo?.accessToken ?? "")")
            debugPrint("Refresh Token: \(tokenInfo?.refreshToken ?? "")")
            let expireTime = Date().timeIntervalSince1970 + (tokenInfo?.expireIn ?? 0)
            self.saveAccessToken(tokenInfo?.accessToken ?? "",expireIn: expireTime)
            self.saveRefreshToken(tokenInfo?.refreshToken ?? "")
            self.completion?(tokenInfo?.accessToken ?? "", true)
        }
    }
}

//MARK : CRUD
extension DataPodsUtils {
    
    func generateDPoPJWTHeader(publicKeyJWK: String) -> [String: Any] {
        let header: [String: Any] = [
            "alg": "ES256",
            "typ": "dpop+jwt",
            "jwk": publicKeyJWK
        ]
        return header
    }
    
    func generateJWTClaims(httpTokenUsageURL: String, httpMethod: String, dpopUniqueIdentifier: String) -> [String: Any] {
        let epochTimeInSeconds = Int(Date().timeIntervalSince1970)
        let claims: [String: Any] = [
            "htu": httpTokenUsageURL,
            "htm": httpMethod,
            "jti": dpopUniqueIdentifier,
            "iat": epochTimeInSeconds
        ]
        return claims
    }
    
    //2.1 Create a folder
    func createFolder(completion: @escaping((Bool) -> Void)) {
        guard let keyPair = self.retrieveKeyPairFromUserDefaults() else {return}
        let dpopUniqueIdentifier = UUID().uuidString
        let publicKeyJWK = exportPublicKeyAsJWK(publickKey: keyPair.publicKey, keyID: dpopUniqueIdentifier) ?? [:]
        let header: [String: Any] = [
            "alg": "ES256",
            "typ": "dpop+jwt",
            "jwk": publicKeyJWK
        ]
        let epochTimeInSeconds = Int(Date().timeIntervalSince1970)
        let httpTokenUsageURL = userProvidedURL + "/DataWallet/Backups/"
        let claims: [String: Any] = [
            "htu": httpTokenUsageURL,
            "htm": "PUT",
            "jti": dpopUniqueIdentifier,
            "iat": epochTimeInSeconds
        ]
        let dpopJWT = generateJWT(privateKey: keyPair.privateKey, header: header, claims: claims) ?? ""
        let accessToken = getAccessToken() ?? ""
        let headers = [
            "accept": "text/turtle;q=1.0, */*;q=0.5",
            "authorization": "DPoP \(accessToken)",
            "dpop": dpopJWT,
            "link": "<http://www.w3.org/ns/ldp#BasicContainer>; rel='type'"
        ]
        
        var request = URLRequest(url: URL(string: httpTokenUsageURL)!)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = headers
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error creating folder: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                print("Status code2: \(statusCode)")
                completion(true)
                // Handle the response as needed
            }
        }
        task.resume()
    }
    
    func uploadFile(fileName: String, mimeType: String, fileData: Data, completion: @escaping((Bool) -> Void)){
        guard let keyPair = self.retrieveKeyPairFromUserDefaults() else {return}
        let dpopUniqueIdentifier = UUID().uuidString
        let publicKeyJWK = exportPublicKeyAsJWK(publickKey: keyPair.publicKey, keyID: dpopUniqueIdentifier) ?? [:]
        let header: [String: Any] = [
            "alg": "ES256",
            "typ": "dpop+jwt",
            "jwk": publicKeyJWK
        ]
        let epochTimeInSeconds = Int(Date().timeIntervalSince1970)
        let httpTokenUsageURL = userProvidedURL + "/DataWallet/Backups/"
        let claims: [String: Any] = [
            "htu": httpTokenUsageURL,
            "htm": "POST",
            "jti": dpopUniqueIdentifier,
            "iat": epochTimeInSeconds
        ]
        let dpopJWT = generateJWT(privateKey: keyPair.privateKey, header: header, claims: claims) ?? ""
        let accessToken = getAccessToken() ?? ""
        let headers = [
            "accept": "*/*",
            "authorization": "DPoP \(accessToken)",
            "dpop": dpopJWT,
            "slug": fileName,
            "content-type": mimeType
        ]
        
        var request = URLRequest(url: URL(string: httpTokenUsageURL)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = fileData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error uploading file: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                print("Status code3: \(statusCode)")
                completion(true)
                // Handle the response as needed
            }
        }
        task.resume()
    }
    
    func downloadFile(fileName: String,completion: @escaping (Result<String, Error>) -> Void) {
        guard let keyPair = self.retrieveKeyPairFromUserDefaults() else {return}
        let dpopUniqueIdentifier = UUID().uuidString
        let publicKeyJWK = exportPublicKeyAsJWK(publickKey: keyPair.publicKey, keyID: dpopUniqueIdentifier) ?? [:]
        let header: [String: Any] = [
            "alg": "ES256",
            "typ": "dpop+jwt",
            "jwk": publicKeyJWK
        ]
        let epochTimeInSeconds = Int(Date().timeIntervalSince1970)
        let httpTokenUsageURL = userProvidedURL + "/DataWallet/Backups/" + fileName
        let claims: [String: Any] = [
            "htu": httpTokenUsageURL,
            "htm": "GET",
            "jti": dpopUniqueIdentifier,
            "iat": epochTimeInSeconds
        ]
        let dpopJWT = generateJWT(privateKey: keyPair.privateKey, header: header, claims: claims) ?? ""
        let accessToken = getAccessToken() ?? ""
        let headers = [
            "accept": "text/turtle;q=1.0, */*;q=0.5",
            "authorization": "DPoP \(accessToken)",
            "dpop": dpopJWT
        ]
        
        var request = URLRequest(url: URL(string: httpTokenUsageURL)!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error downloading file: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if let data = data {
                    // Save the downloaded data to a file
                    let fileManager = FileManager.default
                    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let filePath = documentsDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try data.write(to: filePath)
                        completion(.success(filePath.path))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Request failed with status code: \(statusCode)"])
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    func getLatestBackupFileDate(completion: @escaping((String?) -> Void)) {
        listFilesInFolder { files in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy-hhmmss"
            var latestDate: Date?
            for dateString in files ?? [] {
                if let date = dateFormatter.date(from: dateString.replacingOccurrences(of: ".db", with: "")) {
                    if latestDate == nil || date > latestDate! {
                        latestDate = date
                    }
                }
            }
            if let latestDate = latestDate {
                let outputDateFormatter = DateFormatter()
                outputDateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                let latest = outputDateFormatter.string(from: latestDate)
                completion(latest)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.getLatestBackupFileDate(completion: completion)
                }
            }
        }
    }
    
    func getLatestBackupFileDate2(completion: @escaping((String?) -> Void)) {
        listFilesInFolder { files in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy-HHmmss"
            var latestDate: Date?
            var latestDateString: String?
            for dateString in files ?? [] {
                let timestampString = dateString.replacingOccurrences(of: ".db", with: "")
                if let timestamp = TimeInterval(timestampString) {
                    let date = Date(timeIntervalSince1970: timestamp)
                    
                    if latestDate == nil || date > latestDate! {
                        latestDate = date
                        latestDateString = dateString.replacingOccurrences(of: ".db", with: "")
                    }
                }

//                if let date = dateFormatter.date(from: dateString.replacingOccurrences(of: ".db", with: "")) {
//                    if latestDate == nil || date > latestDate! {
//                        latestDate = date
//                    }
//                }
            }
            if let latestDate = latestDate {
                let outputDateFormatter = DateFormatter()
                outputDateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                let latest = outputDateFormatter.string(from: latestDate)
                completion(latestDateString)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.getLatestBackupFileDate(completion: completion)
                }
            }
        }
    }

    func listFilesInFolder(completion: @escaping(([String]?) -> Void)) {
        guard let keyPair = self.retrieveKeyPairFromUserDefaults() else {return}
        let dpopUniqueIdentifier = UUID().uuidString
        let publicKeyJWK = exportPublicKeyAsJWK(publickKey: keyPair.publicKey, keyID: dpopUniqueIdentifier) ?? [:]
        let header: [String: Any] = [
            "alg": "ES256",
            "typ": "dpop+jwt",
            "jwk": publicKeyJWK
        ]
        let epochTimeInSeconds = Int(Date().timeIntervalSince1970)
        let httpTokenUsageURL = userProvidedURL + "/DataWallet/Backups/"
        let claims: [String: Any] = [
            "htu": httpTokenUsageURL,
            "htm": "GET",
            "jti": dpopUniqueIdentifier,
            "iat": epochTimeInSeconds
        ]
        let dpopJWT = generateJWT(privateKey: keyPair.privateKey, header: header, claims: claims) ?? ""
        let accessToken = getAccessToken() ?? ""
        let headers = [
            "accept": "text/turtle;q=1.0, */*;q=0.5",
            "authorization": "DPoP \(accessToken)",
            "dpop": dpopJWT
        ]
        
        var request = URLRequest(url: URL(string: httpTokenUsageURL)!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error listing files: \(error)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                print("Status code: \(statusCode)")
                
                if let data = data {
                    // Process the list of files in the folder from the response data
                    let files = self.parseFilesFromResponse(data: data)
                    print("Files in folder: \(files)")
                    completion(files)
                }
            }
        }
        task.resume()
    }
    
    func parseFilesFromResponse(data: Data) -> [String] {
        var files: [String] = []
        
        if let turtleString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "") {
            let regexPattern = "ldp:contains+<(.*)>;"
            
            if let regex = try? NSRegularExpression(pattern: regexPattern) {
                let matches = regex.matches(in: turtleString, range: NSRange(turtleString.startIndex..., in: turtleString))
                
                let values = matches.map { match -> String in
                    let range = Range(match.range(at: 1), in: turtleString)!
                    var matchedString = String(turtleString[range])
                    if let decodedValue = matchedString.removingPercentEncoding {
                        matchedString = decodedValue
                    }
                    return matchedString
                }
                print("Extracted values: \(values)")
                files = values
            }        }
        
        //Since the file name contains ", " so we can't seperate it with it. splitting using ", " require iOS 16
        return files.first?.replacingOccurrences(of: ">", with: "").replacingOccurrences(of: "<", with: "").split(separator: ",").map({ sub in
            String(sub)
        }) as? [String] ?? []
    }
}

extension Data {
    static func randomData(ofSize size: Int) -> Data {
        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes { mutableBytes -> Int32 in
            if let bytes = mutableBytes.baseAddress {
                return SecRandomCopyBytes(kSecRandomDefault, size, bytes)
            }
            return errSecMemoryError
        }
        
        if result == errSecSuccess {
            return data
        } else {
            fatalError("Failed to generate random data: \(result)")
        }
    }
    
    func base64URLEncodedString() -> String {
        var base64String = self.base64EncodedString()
        base64String = base64String.replacingOccurrences(of: "+", with: "-")
        base64String = base64String.replacingOccurrences(of: "/", with: "_")
        base64String = base64String.replacingOccurrences(of: "=", with: "")
        return base64String
    }
}

extension Dictionary where Key == String, Value == String {
    func queryParameters() -> String {
        var queryItems: [URLQueryItem] = []
        for (key, value) in self {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        if !queryItems.isEmpty {
            var urlComponents = URLComponents()
            urlComponents.queryItems = queryItems
            if let encodedQuery = urlComponents.query?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return encodedQuery
            }
        }
        return ""
    }
}
