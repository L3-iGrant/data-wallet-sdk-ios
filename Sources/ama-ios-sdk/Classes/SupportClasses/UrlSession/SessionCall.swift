//
//  SessionCall.swift
//  Nejree
//
//  Created by sreelekh N on 07/04/22.
//  Copyright © 2022 developer. All rights reserved.
//

import Foundation

protocol SessionCallProrocol {
    func request(urlRequest: URLRequest) async -> (SessionResponce?, String?)
}

final class SessionCall: SessionCallProrocol {
    
    private var session = URLSession.shared
    private var task: URLSessionTask?
    
    func request(urlRequest: URLRequest) async -> (SessionResponce?, String?) {
        if #available(iOS 15.0, *) {
            do {
                let data = try await session.data(for: urlRequest)
                return (data, nil)
            } catch {
                print(error.localizedDescription)
                return (nil, error.localizedDescription)
            }
        } else {
            // Fallback on earlier versions
            let (data, response, error) = await fetchData(urlRequest: urlRequest)
            if error == nil {
                if let serverData = data, let serverResonse = response {
                    let data = SessionResponce(serverData, serverResonse)
                    return (data, nil)
                }
                return (nil, error?.localizedDescription)
            } else {
                return (nil, error?.localizedDescription)
            }
        }
    }
    
    private func fetchData(urlRequest: URLRequest) async -> (Data?, URLResponse?, Error?) {
        await withCheckedContinuation { continuation in
            task = session.dataTask(with: urlRequest, completionHandler: { data, response, error in
                continuation.resume(returning: (data, response, error))
            })
            self.task?.resume()
        }
    }
}

typealias SessionResponce = (Data, URLResponse)
