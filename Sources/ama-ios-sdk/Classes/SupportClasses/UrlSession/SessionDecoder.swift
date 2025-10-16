//
//  SessionDecoder.swift
//  Nejree
//
//  Created by sreelekh N on 19/04/22.
//  Copyright © 2022 developer. All rights reserved.
//

import Foundation
protocol SessionDecoderDelegate {
    func decodeData<T: Decodable>(res: SessionResponce?, decode: T.Type) async -> Result<T?, NetworkResponse>
}

struct SessionDecoder: SessionDecoderDelegate {
    
    func decodeData<T: Decodable>(res: SessionResponce?, decode: T.Type) async -> Result<T?, NetworkResponse> {
        if let sessionResponse = res {
            let data = sessionResponse.0
            let response = sessionResponse.1
            if printPostOn {
                print(data.prettyPrintedJSONString())
            }
            if let httpResponse = response as? HTTPURLResponse {
                let result = self.handleNetworkResponse(httpResponse)
                switch result {
                case .success:
                    let decoder = JSONDecoder()
                    let parser = T.self
                    do {
                        let object = try decoder.decode(parser, from: data)
                        return .success(object)
                    } catch {
                        print(error)
                        return .failure(NetworkResponse.unableToDecode)
                    }
                case .failure(let networkFailureError):
                    return .failure(networkFailureError)
                }
            }
        }
        return .failure(NetworkResponse.offline)
    }
    
    private func handleNetworkResponse(_ response: HTTPURLResponse) -> ResultType<NetworkResponse> {
        switch response.statusCode {
        case 200...299: return .success
        case 401...500: return .failure(NetworkResponse.authenticationError)
        case 501...599: return .failure(NetworkResponse.badRequest)
        case 600: return .failure(NetworkResponse.outdated)
        default: return .failure(NetworkResponse.failed)
        }
    }
}

enum NetworkResponse: String, Error {
    case success
    case authenticationError = "You need to be authenticated first."
    case badRequest = "Bad request"
    case outdated = "The url you requested is outdated."
    case failed = "Network request failed."
    case noData = "Response returned with no data to decode."
    case unableToDecode = "We could not decode the response."
    case offline = "The Internet connection appears to be offline."
}
