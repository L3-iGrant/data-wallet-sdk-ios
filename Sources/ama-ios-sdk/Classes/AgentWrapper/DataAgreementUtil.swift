//
//  DataAgreementUtil.swift
//  dataWallet
//
//  Created by iGrant on 21/03/25.
//

import Foundation


class DataAgreementUtil {
    
    static let shared = DataAgreementUtil()
    
    func getDataAgreement() async -> DataAgreementContext? {
        let url = "https://raw.githubusercontent.com/L3-iGrant/datawallet-metadata/refs/heads/main/data-agreement/passport-for-payment-pilot.json"
        var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "GET"
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpRes = response as? HTTPURLResponse
            if let statusCode = httpRes?.statusCode, statusCode == 200 {
                let stringData = String.init(data: data, encoding: .utf8)
                let dataAgreementBody: Body? = try? JSONDecoder().decode(Body.self, from: data)
                
                let hardcodedMessage = DataAgreementMessage(
                    body: dataAgreementBody,
                    id: "msg_123",
                    from: "did:example:from",
                    to: "did:example:to",
                    createdTime: "2023-10-01T12:00:00Z",
                    type: "DataAgreement"
                )

                let dataAgreementContext = DataAgreementContext(
                    message: hardcodedMessage,
                    messageType: "DataAgreement",
                    validated: nil,
                    receipt: nil
                )
                return dataAgreementContext
            } else if let statusCode = httpRes?.statusCode, statusCode >= 400 {
                return nil
            }
        } catch {
            return nil
        }
        return nil
    }
}
