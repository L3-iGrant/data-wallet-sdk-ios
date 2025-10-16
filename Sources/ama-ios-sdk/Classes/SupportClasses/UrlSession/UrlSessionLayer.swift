//
//  UrlSessionLayer.swift
//  SocialMob
//
//  Created by sreelekh N on 28/02/22.
//

import Foundation
let printPostOn = true
enum LoadingState {
    case initialState
    case loadingState
    case pagination
    case finished
    case noInternet
    case serverError(String)
    case emptyPage
}

public enum NetworkMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public typealias SessionHeaders = [String: String]?
public typealias PARAMS = [String: Any]?

struct UrlSessionLayer {
    
    var sessionDelegate: SessionCallProrocol
    var decoderDelegate: SessionDecoderDelegate
    init(
        session: SessionCallProrocol = SessionCall(),
        decode: SessionDecoderDelegate = SessionDecoder()
    ) {
        sessionDelegate = session
        decoderDelegate = decode
    }
    
    func sendRequest<T: Decodable, Q: Encodable>(url: UrlQuery,
                                                 headers: SessionHeaders = nil,
                                                 params: Q,
                                                 decodingType: T.Type) async -> Result<T?, NetworkResponse> {
        
        let urlString = url.rawUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlConverted = urlString.toUrl
        var urlRequest = URLRequest(url: urlConverted)
        urlRequest.httpMethod = url.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let headers = headers {
            if printPostOn {
                debugPrint("sending header = \(headers)")
            }
            urlRequest.allHTTPHeaderFields = headers
        }
        if printPostOn {
            debugPrint(urlString)
        }
        
        switch url.method {
        case .post:
            do {
                let body = try JSONEncoder().encode(params)
                urlRequest.httpBody = body
            } catch {}
            printEncode(codable: params, url: url)
        default:
            break
        }
        
        let sessionResponse = await sessionDelegate.request(urlRequest: urlRequest)
        if sessionResponse.0 == nil {
            let error = handleErrorSession(sessionResponse.1, decode: decodingType)
            return error
        } else {
            return await decoderDelegate.decodeData(res: sessionResponse.0, decode: decodingType)
        }
    }
    
    private func printEncode<T: Encodable>(codable: T, url: UrlQuery) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(codable), let output = String(data: data, encoding: .utf8) {
                if printPostOn {
                    debugPrint("sending json = \(output)")
                }
            }
        }
    }
    
    private func handleErrorSession<T: Decodable>(_ error: String?, decode: T.Type) -> Result<T?, NetworkResponse> {
        if error == "unsupported URL" {
            return .failure(.badRequest)
        } else {
            return .failure(.offline)
        }
    }
}

enum ResultType<String> {
    case success
    case failure(String)
}
