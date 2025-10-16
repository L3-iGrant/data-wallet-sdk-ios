//
//  ReceiptModel.swift
//  dataWallet
//
//  Created by iGrant on 13/05/25.
//

import Foundation

struct ReceiptItemModel: Codable {
    let address: ReceiptAddress
    let delivery: Delivery
    let itemProperty: ItemProperty
    let monetaryTotal: MonetaryTotal
    let partyIdentification: ReceiptPartyIdentification
    let partyName: ReceiptPartyName
    let paymentMeans: ReceiptPaymentMeans
    let purchaseReceipt: PurchaseReceipt
    let taxTotal: ReceiptTaxTotal

    enum CodingKeys: String, CodingKey {
        case address
        case delivery
        case itemProperty = "item_property"
        case monetaryTotal = "monetary_total"
        case partyIdentification = "party_identification"
        case partyName = "party_name"
        case paymentMeans = "payment_means"
        case purchaseReceipt = "purchase_receipt"
        case taxTotal = "tax_total"
    }
}

struct ReceiptAddress: Codable {
    let cityName: String?
    let countryIdentifier: String?
    let postcode: String?
    let streetName: String?

    enum CodingKeys: String, CodingKey {
        case cityName = "city_name"
        case countryIdentifier = "country_identifier"
        case postcode
        case streetName = "street_name"
    }
}

struct Delivery: Codable {
    let actualDeliveryDate: String
    let actualDeliveryTime: String

    enum CodingKeys: String, CodingKey {
        case actualDeliveryDate = "actual_delivery_date"
        case actualDeliveryTime = "actual_delivery_time"
    }
}

struct ItemProperty: Codable {
    let itemPropertyName: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case itemPropertyName = "item_property_name"
        case value
    }
}

struct MonetaryTotal: Codable {
    let lineExtensionAmount: String
    let payableAmount: String
    let taxInclusiveAmount: String

    enum CodingKeys: String, CodingKey {
        case lineExtensionAmount = "line_extension_amount"
        case payableAmount = "payable_amount"
        case taxInclusiveAmount = "tax_inclusive_amount"
    }
}

struct ReceiptPartyIdentification: Codable {
    let id: String
}

struct ReceiptPartyName: Codable {
    let name: String
}

struct ReceiptPaymentMeans: Codable {
    let cardAccount: CardAccount
    let paymentMeansCode: String

    enum CodingKeys: String, CodingKey {
        case cardAccount = "card_account"
        case paymentMeansCode = "payment_means_code"
    }
}

struct CardAccount: Codable {
    let accountNumberID: String
    let networkID: String

    enum CodingKeys: String, CodingKey {
        case accountNumberID = "account_number_id"
        case networkID = "network_id"
    }
}

struct PurchaseReceipt: Codable {
    let documentCurrencyCode: String
    let id: String
    let issueDate: String
    let legalMonetaryTotal: String
    let payment: Payment
    let purchaseReceiptLine: PurchaseReceiptLine
    let sellerSupplierParty: SellerSupplierParty
    let taxIncludedIndicator: String

    enum CodingKeys: String, CodingKey {
        case documentCurrencyCode = "document_currency_code"
        case id
        case issueDate = "issue_date"
        case legalMonetaryTotal = "legal_monetary_total"
        case payment
        case purchaseReceiptLine = "purchase_receipt_line"
        case sellerSupplierParty = "seller_supplier_party"
        case taxIncludedIndicator = "tax_included_indicator"
    }
}

struct Payment: Codable {
    let authorizationID: String
    let paidAmount: String
    let transactionID: String

    enum CodingKeys: String, CodingKey {
        case authorizationID = "authorization_id"
        case paidAmount = "paid_amount"
        case transactionID = "transaction_id"
    }
}

struct PurchaseReceiptLine: Codable {
    let id: String
    let item: ReceiptItem
    let quantity: String
    let taxInclusiveLineExtensionAmount: String

    enum CodingKeys: String, CodingKey {
        case id
        case item
        case quantity
        case taxInclusiveLineExtensionAmount = "tax_inclusive_line_extension_amount"
    }
}

struct ReceiptItem: Codable {
    let commodityClassification: CommodityClassification

    enum CodingKeys: String, CodingKey {
        case commodityClassification = "commodity_classification"
    }
}

struct CommodityClassification: Codable {
    let itemClassificationCode: String

    enum CodingKeys: String, CodingKey {
        case itemClassificationCode = "item_classification_code"
    }
}

struct SellerSupplierParty: Codable {
    let supplierPartyID: String

    enum CodingKeys: String, CodingKey {
        case supplierPartyID = "supplier_party_id"
    }
}

struct ReceiptTaxTotal: Codable {
    let taxAmount: String
    let taxSubtotal: ReceiptTaxSubtotal

    enum CodingKeys: String, CodingKey {
        case taxAmount = "tax_amount"
        case taxSubtotal = "tax_subtotal"
    }
}

struct ReceiptTaxSubtotal: Codable {
    let percent: String
    let taxAmount: String
    let taxCategory: ReceiptTaxCategory

    enum CodingKeys: String, CodingKey {
        case percent
        case taxAmount = "tax_amount"
        case taxCategory = "tax_category"
    }
}

struct ReceiptTaxCategory: Codable {
    let taxScheme: TaxScheme

    enum CodingKeys: String, CodingKey {
        case taxScheme = "tax_scheme"
    }
}

struct TaxScheme: Codable {
    let name: String
}
