//
//  ReceiptModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 21/09/22.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let receiptModel = try? newJSONDecoder().decode(ReceiptModel.self, from: jsonData)

import Foundation

// MARK: - ReceiptModel
struct ReceiptNotificationModel: Codable {
    let type, id: String?
    let body: ReceiptModel?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case body
    }
}

// MARK: - Body
struct ReceiptModel: Codable {
    let instanceID: String?
    let blockchainReceipt: BlockchainReceipt?
    let blink, mydataDid: String?

    enum CodingKeys: String, CodingKey {
        case instanceID = "instance_id"
        case blockchainReceipt = "blockchain_receipt"
        case blink
        case mydataDid = "mydata_did"
    }
}

// MARK: - BlockchainReceipt
struct BlockchainReceipt: Codable {
    let blockHash: String?
    let blockNumber: Int?
    let contractAddress: JSONNull?
    let cumulativeGasUsed, effectiveGasPrice: Int?
    let from: String?
    let gasUsed: Int?
    let logs: [Log]?
    let logsBloom: String?
    let status: Int?
    let to, transactionHash: String?
    let transactionIndex: Int?
    let type: String?
}

// MARK: - Log
struct Log: Codable {
    let address, blockHash: String?
    let blockNumber: Int?
    let data: String?
    let logIndex: Int?
    let removed: Bool?
    let topics: [String]?
    let transactionHash: String?
    let transactionIndex: Int?
}

